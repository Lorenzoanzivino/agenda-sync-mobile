import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/app_strings.dart';
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

  List<SharedCalendarModel> _cachedCalendars = [];

  @override
  void initState() {
    super.initState();
    _calendarIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

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
    final List<String> briefingTimes = List.generate(48, (index) {
      final int hour = index ~/ 2;
      final String minute = (index % 2 == 0) ? "00" : "30";
      return "${hour.toString().padLeft(2, '0')}:$minute";
    });

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
                const Text(AppStrings.impostazioni, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text(AppStrings.briefingLabel, style: TextStyle(color: Colors.white70, fontSize: 16)),
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
                      items: briefingTimes.map((String time) {
                        return DropdownMenuItem<String>(value: time, child: Text(time));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _preferredNotificationTime = val);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${AppStrings.snackOrarioAggiornato}$val"), backgroundColor: Colors.green));
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
                    label: const Text(AppStrings.btnGestisciCondivisione, style: TextStyle(color: Colors.white)),
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
        title: const Text(AppStrings.alertEliminaCalTitolo, style: TextStyle(color: Colors.white)),
        content: Text(AppStrings.alertEliminaCalCorpo.replaceFirst('{name}', calendarName), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.btnAnnulla, style: TextStyle(color: Colors.white54)),
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
            child: const Text(AppStrings.btnElimina, style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showOtpInfoDialog(String calendarName, String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppAtmospheres.sharedBg,
        title: const Text(AppStrings.dialogVisualizzaOtp, style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nome: $calendarName", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Usa questo codice per far unire un altro utente:", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 15),
            SelectableText(code, style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Codice copiato negli appunti!')));
                Navigator.pop(ctx);
              }
            },
            child: const Text(AppStrings.btnCopia, style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.btnChiudi, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDayAgendaModal(BuildContext context, DateTime day, List<TaskModel> tasks, Color bgColor, bool isSharedView, String? calendarId) {
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
            child: _DayAgendaModalContent(
              day: day,
              initialTasks: tasks,
              bgColor: bgColor,
              isSharedView: isSharedView,
              calendarId: calendarId,
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
                            return _buildCalendarView(AppStrings.dashboardPrivata, false, null, null);
                          } else {
                            if (_cachedCalendars.isEmpty) {
                              return _buildEmptySharedView();
                            } else {
                              int calendarIndex = index - 1;
                              if (calendarIndex >= _cachedCalendars.length) {
                                calendarIndex = _cachedCalendars.length - 1;
                              }
                              final calendar = _cachedCalendars[calendarIndex];
                              return _buildCalendarView(calendar.nome, true, calendar.id, calendar.inviteCode);
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
            const Text(AppStrings.emptySharedMessage, style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
              ),
              icon: const Icon(Icons.add_link, color: Colors.white),
              label: const Text(AppStrings.btnCreaUnisciti, style: TextStyle(color: Colors.white)),
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
          Row(
            children: [
              const Text(AppStrings.visualeMese, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              if (isShared && currentCalendar != null && currentCalendar.inviteCode != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showOtpInfoDialog(currentCalendar!.nome, currentCalendar.inviteCode!),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.priority_high, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ],
          ),
          Row(
            children: [
              if (isShared && currentCalendar != null) ...[
                Container(
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.black, size: 20),
                    onPressed: () => _confirmDeleteCalendar(currentCalendar!.id, currentCalendar.nome),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Container(
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.black, size: 20),
                  onPressed: () {
                    if (isShared && _cachedCalendars.isEmpty) {
                      showCalendarManagementModal(context);
                    } else {
                      showTaskFormModal(
                        context,
                        context.read<TaskCubit>(),
                        isShared: isShared,
                        forcedCalendarId: currentCalendar?.id,
                        forcedDate: _selectedDay ?? DateTime.now(),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                  onPressed: _showSettingsModal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(String title, bool isSharedView, String? calendarId, String? inviteCode) {
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
                        locale: 'it_IT',
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        rowHeight: 65,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                            _selectedDay = null;
                          });
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });

                          final tasksForDay = _getEventsForDay(selectedDay, allTasks, isSharedView, calendarId);

                          Color modalBgColor = AppAtmospheres.privateBg;
                          if (isSharedView && _cachedCalendars.isNotEmpty) {
                            int sharedIdx = _calendarIndex - 1;
                            if (sharedIdx >= _cachedCalendars.length) sharedIdx = _cachedCalendars.length - 1;
                            modalBgColor = AppAtmospheres.getSharedBg(sharedIdx);
                          }

                          _showDayAgendaModal(context, selectedDay, tasksForDay, modalBgColor, isSharedView, calendarId);
                        },
                        eventLoader: (day) => _getEventsForDay(day, allTasks, isSharedView, calendarId),
                        calendarStyle: const CalendarStyle(defaultTextStyle: TextStyle(color: Colors.white), weekendTextStyle: TextStyle(color: Colors.white70), outsideTextStyle: TextStyle(color: Colors.white38), todayDecoration: BoxDecoration(color: Colors.white38, shape: BoxShape.rectangle, borderRadius: BorderRadius.all(Radius.circular(12))), selectedDecoration: BoxDecoration(color: Colors.white, shape: BoxShape.rectangle, borderRadius: BorderRadius.all(Radius.circular(12))), selectedTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white), rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white)),
                        daysOfWeekStyle: const DaysOfWeekStyle(weekdayStyle: TextStyle(color: Colors.white), weekendStyle: TextStyle(color: Colors.white70)),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            if (events.isEmpty) return const SizedBox();

                            return Positioned(
                              right: 4,
                              bottom: 4,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: isSharedView ? Colors.cyanAccent.withValues(alpha: 0.9) : Colors.redAccent.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${events.length}',
                                  style: TextStyle(
                                    color: isSharedView ? Colors.black : Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
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
                  _buildNavItem(Icons.dashboard_rounded, AppStrings.navHome, 0),
                  _buildNavItem(Icons.calendar_month_rounded, AppStrings.navCalendario, 1),
                  _buildNavItem(Icons.logout_rounded, AppStrings.navLogout, 2),
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

class _DayAgendaModalContent extends StatefulWidget {
  final DateTime day;
  final List<TaskModel> initialTasks;
  final Color bgColor;
  final bool isSharedView;
  final String? calendarId;

  const _DayAgendaModalContent({
    required this.day,
    required this.initialTasks,
    required this.bgColor,
    required this.isSharedView,
    required this.calendarId,
  });

  @override
  State<_DayAgendaModalContent> createState() => _DayAgendaModalContentState();
}

class _DayAgendaModalContentState extends State<_DayAgendaModalContent> {
  final List<String> _selectedTaskIds = [];
  bool _isSelectionMode = false;

  void _toggleSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
        if (_selectedTaskIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedTaskIds.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        List<TaskModel> tasks = widget.initialTasks;
        if (state is TaskLoaded) {
          final targetDayUtc = DateTime.utc(widget.day.year, widget.day.month, widget.day.day);
          tasks = state.tasks.where((task) {
            final parsedDate = DateTime.tryParse(task.dataInizio) ?? DateTime.now();
            final taskDayUtc = DateTime.utc(parsedDate.year, parsedDate.month, parsedDate.day);

            final isSameDay = taskDayUtc == targetDayUtc;
            final isTaskShared = task.sharedCalendarId != null;
            final matchesType = widget.isSharedView ? isTaskShared : !isTaskShared;
            final matchesCalendar = !widget.isSharedView || task.sharedCalendarId == widget.calendarId;

            return isSameDay && matchesType && matchesCalendar;
          }).toList();

          tasks.sort((a, b) {
            if (a.tuttoIlGiorno && !b.tuttoIlGiorno) return -1;
            if (!a.tuttoIlGiorno && b.tuttoIlGiorno) return 1;
            final dateA = DateTime.tryParse(a.dataInizio) ?? DateTime.now();
            final dateB = DateTime.tryParse(b.dataFine) ?? DateTime.now();
            return dateA.compareTo(dateB);
          });
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
          decoration: BoxDecoration(
            color: widget.bgColor.withValues(alpha: 0.9),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_isSelectionMode)
                    TextButton.icon(
                      onPressed: () {
                        context.read<TaskCubit>().bulkDeleteTasks(List<String>.from(_selectedTaskIds));
                        _exitSelectionMode();
                      },
                      icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                      label: Text("Elimina (${_selectedTaskIds.length})", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    )
                  else
                    Container(width: 40),
                  Container(
                    width: 50, height: 5,
                    decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(10)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                    onPressed: () {
                      Navigator.pop(context);
                      showTaskFormModal(
                        context,
                        context.read<TaskCubit>(),
                        isShared: widget.isSharedView,
                        forcedCalendarId: widget.calendarId,
                        forcedDate: widget.day,
                      );
                    },
                  )
                ],
              ),
              const SizedBox(height: 15),
              Text(
                "${AppStrings.agendaDel} ${widget.day.day.toString().padLeft(2, '0')}/${widget.day.month.toString().padLeft(2, '0')}/${widget.day.year}",
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: tasks.isEmpty
                    ? const Center(child: Text(AppStrings.nessunTaskData, style: TextStyle(color: Colors.white70, fontSize: 16)))
                    : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 40),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isSelected = _selectedTaskIds.contains(task.id);
                    return GlassTaskCard(
                      title: task.titolo,
                      description: task.descrizione,
                      colorHex: task.colore,
                      isShared: task.sharedCalendarId != null,
                      isSelectedMode: _isSelectionMode,
                      isSelected: isSelected,
                      onLongPress: () {
                        setState(() {
                          _isSelectionMode = true;
                          _toggleSelection(task.id);
                        });
                      },
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelection(task.id);
                        } else {
                          Navigator.pop(context);
                          showTaskDetailsModal(context, context.read<TaskCubit>(), task);
                        }
                      },
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
}