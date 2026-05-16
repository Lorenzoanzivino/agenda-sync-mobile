import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/colors.dart';
import '../../domain/models/task_model.dart';
import '../viewmodels/task_cubit.dart';
import '../viewmodels/auth_cubit.dart';
import '../viewmodels/calendar_cubit.dart';
import '../widgets/atmosphere_background.dart';
import '../widgets/glass_task_card.dart';
import '../widgets/task_modals.dart';
import '../widgets/calendar_management_modal.dart';
import 'home_page.dart';

class CalendarPage extends StatefulWidget {
  final int initialIndex;
  const CalendarPage({super.key, this.initialIndex = 0});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late PageController _pageController;
  late int _calendarIndex;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  String _preferredNotificationTime = "08:00";

  @override
  void initState() {
    super.initState();
    _calendarIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  List<TaskModel> _getEventsForDay(DateTime day, List<TaskModel> allTasks, bool isSharedView) {
    final filtered = allTasks.where((task) {
      final taskDate = DateTime.tryParse(task.dataInizio)?.toLocal() ?? DateTime.now();
      final isSameDay = taskDate.year == day.year && taskDate.month == day.month && taskDate.day == day.day;

      final isTaskShared = task.sharedCalendarNome != null;
      final matchesType = isSharedView ? isTaskShared : !isTaskShared;

      return isSameDay && matchesType;
    }).toList();

    filtered.sort((a, b) {
      if (a.tuttoIlGiorno && !b.tuttoIlGiorno) return -1;
      if (!a.tuttoIlGiorno && b.tuttoIlGiorno) return 1;
      final dateA = DateTime.tryParse(a.dataInizio) ?? DateTime.now();
      final dateB = DateTime.tryParse(b.dataInizio) ?? DateTime.now();
      return dateA.compareTo(dateB);
    });

    return filtered;
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(initialIndex: _calendarIndex)));
    } else if (index == 2) {
      context.read<AuthCubit>().logout();
    }
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              // 🔴 MODIFICA QUI: Nero semitrasparente neutro invece di privateBg
              color: Colors.black.withValues(alpha: 0.7),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Impostazioni", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text("Scegli l'orario del briefing mattutino:", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _preferredNotificationTime,
                      // 🔴 MODIFICA QUI: Sfondo del menu a tendina grigio scuro neutro
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      isExpanded: true,
                      items: ["07:00", "08:00", "09:00", "10:00"].map((String time) {
                        return DropdownMenuItem<String>(value: time, child: Text(time));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _preferredNotificationTime = val);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Orario aggiornato alle $val"), backgroundColor: Colors.green));
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
                    ),
                    icon: const Icon(Icons.people_alt, color: Colors.white),
                    label: const Text('Gestisci Condivisione Calendari', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      showCalendarManagementModal(context);
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isShared = _calendarIndex == 1;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AtmosphereBackground(
            backgroundColor: isShared ? AppAtmospheres.sharedBg : AppAtmospheres.privateBg,
            circleColors: isShared ? AppAtmospheres.sharedCircles : AppAtmospheres.privateCircles,
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeaderBar(isShared),
                _buildAtmosphereIndicators(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _calendarIndex = index),
                    children: [
                      _buildCalendarView("Calendario Privato", false),
                      _buildCalendarView("Calendario Condiviso", true)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  Widget _buildHeaderBar(bool isShared) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Visuale Mese", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    final calState = context.read<CalendarCubit>().state;
                    if (isShared && (calState is! CalendarLoaded || calState.sharedCalendars.isEmpty)) {
                      showCalendarManagementModal(context);
                    } else {
                      showTaskFormModal(context, context.read<TaskCubit>(), isShared: isShared);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: _showSettingsModal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(String title, bool isSharedView) {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        List<TaskModel> allTasks = [];
        if (state is TaskLoaded) allTasks = state.tasks;

        final selectedDayTasks = _selectedDay != null ? _getEventsForDay(_selectedDay!, allTasks, isSharedView) : <TaskModel>[];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TableCalendar<TaskModel>(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        rowHeight: 65,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) => setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; }),
                        eventLoader: (day) => _getEventsForDay(day, allTasks, isSharedView),
                        calendarStyle: const CalendarStyle(defaultTextStyle: TextStyle(color: Colors.white), weekendTextStyle: TextStyle(color: Colors.white70), outsideTextStyle: TextStyle(color: Colors.white38), todayDecoration: BoxDecoration(color: Colors.white38, shape: BoxShape.rectangle, borderRadius: BorderRadius.all(Radius.circular(12))), selectedDecoration: BoxDecoration(color: Colors.white, shape: BoxShape.rectangle, borderRadius: BorderRadius.all(Radius.circular(12))), selectedTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white), rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white)),
                        daysOfWeekStyle: const DaysOfWeekStyle(weekdayStyle: TextStyle(color: Colors.white), weekendStyle: TextStyle(color: Colors.white70)),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            if (events.isEmpty) return const SizedBox();

                            bool isDaySelected = isSameDay(date, _selectedDay) || isSameDay(date, DateTime.now());
                            Color dotColor;

                            if (isDaySelected) {
                              dotColor = isSharedView ? AppAtmospheres.sharedBg : AppAtmospheres.privateBg;
                            } else {
                              dotColor = isSharedView ? Colors.cyanAccent : Colors.white;
                            }

                            return Positioned(
                              bottom: 8,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(events.length > 4 ? 4 : events.length, (index) => Container(margin: const EdgeInsets.symmetric(horizontal: 1.5), width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor))),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: selectedDayTasks.isEmpty
                    ? const Center(child: Text("Nessun task per questa data", style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: selectedDayTasks.length,
                  itemBuilder: (context, index) {
                    final task = selectedDayTasks[index];
                    return GlassTaskCard(
                      title: task.titolo,
                      description: task.descrizione,
                      isShared: task.sharedCalendarNome != null,
                      onTap: () => showTaskDetailsModal(context, context.read<TaskCubit>(), task),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAtmosphereIndicators() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(2, (index) => GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5), width: 12, height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _calendarIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.3), boxShadow: _calendarIndex == index ? [BoxShadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 10)] : []),
          ),
        )),
      ),
    );
  }

  Widget _buildCustomBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 90,
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              border: const Border(top: BorderSide(color: Colors.white10, width: 0.5))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.dashboard_rounded, 'Home', 0),
              _buildNavItem(Icons.calendar_month_rounded, 'Calendario', 1),
              _buildNavItem(Icons.logout_rounded, 'Logout', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = index == 1;
    return GestureDetector(
      onTap: () => _onBottomNavTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white54),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }
}