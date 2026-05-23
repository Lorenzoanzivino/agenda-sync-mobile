import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/colors.dart';
import '../../domain/models/task_model.dart';
import '../../domain/models/shared_calendar_model.dart';
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

  // CACHE: Mantiene i calendari visibili durante i caricamenti
  List<SharedCalendarModel> _cachedCalendars = [];

  @override
  void initState() {
    super.initState();
    _calendarIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  // FIX: Conversione sicura e uniforme dei Timezone verso UTC
  List<TaskModel> _getEventsForDay(DateTime day, List<TaskModel> allTasks, bool isSharedView, String? calendarId) {
    final targetDayUtc = DateTime.utc(day.year, day.month, day.day);

    final filtered = allTasks.where((task) {
      final parsedDate = DateTime.tryParse(task.dataInizio) ?? DateTime.now();
      final taskDayUtc = DateTime.utc(parsedDate.year, parsedDate.month, parsedDate.day);

      final isSameDay = taskDayUtc == targetDayUtc;

      final isTaskShared = task.sharedCalendarId != null;
      final matchesType = isSharedView ? isTaskShared : !isTaskShared;
      final matchesCalendar = !isSharedView || task.sharedCalendarId == calendarId;

      return isSameDay && matchesType && matchesCalendar;
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

  void _confirmDeleteCalendar(String calendarId, String calendarName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Elimina Calendario", style: TextStyle(color: Colors.white)),
        content: Text("Sei sicuro di voler eliminare il calendario '$calendarName'? Questa azione è irreversibile.", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annulla", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);

              int totalShared = _cachedCalendars.length;
              if (totalShared > 1 && _calendarIndex == totalShared) {
                _pageController.animateToPage(_calendarIndex - 1, duration: const Duration(milliseconds: 300), curve: Curves.ease);
              }

              context.read<CalendarCubit>().deleteCalendar(calendarId);
            },
            child: const Text("Elimina", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showDayAgendaModal(BuildContext context, DateTime day, List<TaskModel> tasks, Color bgColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<TaskCubit>()),
          BlocProvider.value(value: context.read<CalendarCubit>()),
        ],
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75, // Modale occupa il 75% dello schermo
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 0.9),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "Agenda del ${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}",
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: tasks.isEmpty
                        ? const Center(child: Text("Nessun task per questa data", style: TextStyle(color: Colors.white70, fontSize: 16)))
                        : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 40),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return GlassTaskCard(
                          title: task.titolo,
                          description: task.descrizione,
                          isShared: task.sharedCalendarId != null,
                          onTap: () {
                            Navigator.pop(ctx); // Chiude l'agenda prima di aprire i dettagli
                            showTaskDetailsModal(context, context.read<TaskCubit>(), task);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        if (state is CalendarLoaded) {
          _cachedCalendars = state.sharedCalendars;
        }

        int pageCount = _cachedCalendars.isEmpty ? 2 : _cachedCalendars.length + 1;
        bool isShared = _calendarIndex > 0;

        Color currentBgColor = AppAtmospheres.privateBg;
        List<Color> currentCircles = AppAtmospheres.privateCircles;

        if (isShared && _cachedCalendars.isNotEmpty) {
          int sharedIdx = _calendarIndex - 1;
          if (sharedIdx >= _cachedCalendars.length) {
            sharedIdx = _cachedCalendars.length - 1;
          }
          currentBgColor = AppAtmospheres.getSharedBg(sharedIdx);
          currentCircles = AppAtmospheres.getSharedCircles(sharedIdx);
        } else if (isShared) {
          currentBgColor = AppAtmospheres.sharedBg;
          currentCircles = AppAtmospheres.sharedCircles;
        }

        return Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              AtmosphereBackground(
                backgroundColor: currentBgColor,
                circleColors: currentCircles,
              ),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _buildHeaderBar(isShared),
                    _buildAtmosphereIndicators(pageCount),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) => setState(() => _calendarIndex = index),
                        itemCount: pageCount,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildCalendarView("Calendario Privato", false, null);
                          } else {
                            if (_cachedCalendars.isEmpty) {
                              return _buildEmptySharedView();
                            } else {
                              int calendarIndex = index - 1;
                              if (calendarIndex >= _cachedCalendars.length) {
                                calendarIndex = _cachedCalendars.length - 1;
                              }
                              final calendar = _cachedCalendars[calendarIndex];
                              return _buildCalendarView(calendar.nome, true, calendar.id);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildCustomBottomNav(),
        );
      },
    );
  }

  Widget _buildEmptySharedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text("Non hai ancora calendari condivisi.", style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
              ),
              icon: const Icon(Icons.add_link, color: Colors.white),
              label: const Text('Crea o Unisciti', style: TextStyle(color: Colors.white)),
              onPressed: () => showCalendarManagementModal(context),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar(bool isShared) {
    SharedCalendarModel? currentCalendar;
    if (isShared && _cachedCalendars.isNotEmpty) {
      int sharedIdx = _calendarIndex - 1;
      if (sharedIdx >= 0 && sharedIdx < _cachedCalendars.length) {
        currentCalendar = _cachedCalendars[sharedIdx];
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Visuale Mese", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Row(
            children: [
              if (isShared && currentCalendar != null) ...[
                Container(
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.black),
                    onPressed: () => _confirmDeleteCalendar(currentCalendar!.id, currentCalendar.nome),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Container(
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.black),
                  onPressed: () {
                    if (isShared && _cachedCalendars.isEmpty) {
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

  Widget _buildCalendarView(String title, bool isSharedView, String? calendarId) {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        List<TaskModel> allTasks = [];
        if (state is TaskLoaded) allTasks = state.tasks;

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
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                            _selectedDay = null; // Resetta il giorno selezionato al cambio mese
                          });
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });

                          final tasksForDay = _getEventsForDay(selectedDay, allTasks, isSharedView, calendarId);

                          // Calcola il colore di sfondo per mantenere coerenza visiva nel modale
                          Color modalBgColor = AppAtmospheres.privateBg;
                          if (isSharedView && _cachedCalendars.isNotEmpty) {
                            int sharedIdx = _calendarIndex - 1;
                            if (sharedIdx >= _cachedCalendars.length) sharedIdx = _cachedCalendars.length - 1;
                            modalBgColor = AppAtmospheres.getSharedBg(sharedIdx);
                          }

                          _showDayAgendaModal(context, selectedDay, tasksForDay, modalBgColor);
                        },
                        eventLoader: (day) => _getEventsForDay(day, allTasks, isSharedView, calendarId),
                        calendarStyle: const CalendarStyle(defaultTextStyle: TextStyle(color: Colors.white), weekendTextStyle: TextStyle(color: Colors.white70), outsideTextStyle: TextStyle(color: Colors.white38), todayDecoration: BoxDecoration(color: Colors.white38, shape: BoxShape.rectangle, borderRadius: BorderRadius.all(Radius.circular(12))), selectedDecoration: BoxDecoration(color: Colors.white, shape: BoxShape.rectangle, borderRadius: BorderRadius.all(Radius.circular(12))), selectedTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white), rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white)),
                        daysOfWeekStyle: const DaysOfWeekStyle(weekdayStyle: TextStyle(color: Colors.white), weekendStyle: TextStyle(color: Colors.white70)),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            if (events.isEmpty) return const SizedBox();

                            bool isDaySelected = isSameDay(date, _selectedDay) || isSameDay(date, DateTime.now());
                            Color dotColor;

                            if (isDaySelected) {
                              dotColor = AppAtmospheres.privateBg;
                              if (isSharedView && calendarId != null) {
                                final idx = _cachedCalendars.indexWhere((c) => c.id == calendarId);
                                if (idx != -1) dotColor = AppAtmospheres.getSharedBg(idx);
                              }
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
              const Spacer(), // Riempie lo spazio residuo senza forzare rendering di liste
            ],
          ),
        );
      },
    );
  }

  Widget _buildAtmosphereIndicators(int pageCount) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pageCount, (index) => GestureDetector(
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
          decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              border: const Border(top: BorderSide(color: Colors.white10, width: 0.5))
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 10),
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