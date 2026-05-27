import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/models/task_model.dart';
import '../../domain/models/shared_calendar_model.dart';
import '../viewmodels/task_cubit.dart';
import '../viewmodels/auth_cubit.dart';
import '../viewmodels/auth_state.dart';
import '../viewmodels/calendar_cubit.dart';
import '../widgets/atmosphere_background.dart';
import '../widgets/task_modals.dart';
import '../widgets/calendar_management_modal.dart';
import '../widgets/calendar_bottom_nav.dart';
import '../widgets/calendar_view_widget.dart';
import '../widgets/day_agenda_modal.dart';
import 'home_page.dart';
import 'login_page.dart';

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

  List<TaskModel> _getEventsForDay(
      DateTime day,
      List<TaskModel> allTasks,
      bool isSharedView,
      String? calendarId,
      ) {
    final targetDayUtc = DateTime.utc(day.year, day.month, day.day);

    final filtered = allTasks.where((task) {
      final parsedDate = DateTime.tryParse(task.dataInizio) ?? DateTime.now();
      final taskDayUtc = DateTime.utc(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
      );

      final isSameDay = taskDayUtc == targetDayUtc;
      final isTaskShared = task.sharedCalendarId != null;
      final matchesType = isSharedView ? isTaskShared : !isTaskShared;
      final matchesCalendar =
          !isSharedView || task.sharedCalendarId == calendarId;

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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(initialIndex: _calendarIndex),
        ),
      );
    } else if (index == 2) {
      context.read<AuthCubit>().logout();
    }
  }

  void _showSettingsModal() {
    final List<String> briefingTimes = [];
    for (int h = 1; h <= 24; h++) {
      briefingTimes.add('${h.toString().padLeft(2, '0')}:00');
      if (h < 24) {
        briefingTimes.add('${h.toString().padLeft(2, '0')}:30');
      }
    }

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
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.impostazioni,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  AppStrings.briefingLabel,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _preferredNotificationTime,
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                      isExpanded: true,
                      items: briefingTimes.map((String time) {
                        return DropdownMenuItem<String>(
                          value: time,
                          child: Text(time),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _preferredNotificationTime = val);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "${AppStrings.snackOrarioAggiornato}$val",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.people_alt, color: Colors.white),
                    label: const Text(
                      AppStrings.btnGestisciCondivisione,
                      style: TextStyle(color: Colors.white),
                    ),
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
        title: const Text(
          AppStrings.alertEliminaCalTitolo,
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          AppStrings.alertEliminaCalCorpo.replaceFirst('{name}', calendarName),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              AppStrings.btnAnnulla,
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              int totalShared = _cachedCalendars.length;
              if (totalShared > 1 && _calendarIndex == totalShared) {
                _pageController.animateToPage(
                  _calendarIndex - 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              }
              context.read<CalendarCubit>().deleteCalendar(calendarId);
            },
            child: const Text(
              AppStrings.btnElimina,
              style: TextStyle(color: Colors.redAccent),
            ),
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
        title: const Text(
          AppStrings.dialogVisualizzaOtp,
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Nome: $calendarName",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Usa questo codice per far unire un altro utente:",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 15),
            SelectableText(
              code,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(ctx);

              await Clipboard.setData(ClipboardData(text: code));
              messenger.showSnackBar(
                const SnackBar(content: Text('Codice copiato negli appunti!')),
              );
              nav.pop();
            },
            child: const Text(
              AppStrings.btnCopia,
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              AppStrings.btnChiudi,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarViewWrapper(
      String title,
      bool isSharedView,
      String? calendarId,
      String? inviteCode,
      ) {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        List<TaskModel> allTasks = [];
        if (state is TaskLoaded) allTasks = state.tasks;

        return CalendarViewWidget(
          title: title,
          isSharedView: isSharedView,
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
          eventLoader: (day) =>
              _getEventsForDay(day, allTasks, isSharedView, calendarId),
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

            final tasksForDay = _getEventsForDay(
              selectedDay,
              allTasks,
              isSharedView,
              calendarId,
            );

            Color modalBgColor = AppAtmospheres.privateBg;
            if (isSharedView && _cachedCalendars.isNotEmpty) {
              int sharedIdx = _calendarIndex - 1;
              if (sharedIdx >= _cachedCalendars.length) {
                sharedIdx = _cachedCalendars.length - 1;
              }
              modalBgColor = AppAtmospheres.getSharedBg(sharedIdx);
            }

            showDayAgendaModal(
              context,
              selectedDay,
              tasksForDay,
              modalBgColor,
              isSharedView,
              calendarId,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
          );
        }
      },
      child: BlocBuilder<CalendarCubit, CalendarState>(
        builder: (context, state) {
          if (state is CalendarLoaded) {
            _cachedCalendars = state.sharedCalendars;
          }

          int pageCount = _cachedCalendars.isEmpty
              ? 2
              : _cachedCalendars.length + 1;
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
                          onPageChanged: (index) =>
                              setState(() => _calendarIndex = index),
                          itemCount: pageCount,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildCalendarViewWrapper(
                                AppStrings.dashboardPrivata,
                                false,
                                null,
                                null,
                              );
                            } else {
                              if (_cachedCalendars.isEmpty) {
                                return _buildEmptySharedView();
                              } else {
                                int calendarIndex = index - 1;
                                if (calendarIndex >= _cachedCalendars.length) {
                                  calendarIndex = _cachedCalendars.length - 1;
                                }
                                final calendar =
                                _cachedCalendars[calendarIndex];
                                return _buildCalendarViewWrapper(
                                  calendar.nome,
                                  true,
                                  calendar.id,
                                  calendar.inviteCode,
                                );
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
            bottomNavigationBar: CalendarBottomNav(
              currentIndex: 1, // 1 è l'indice per il Calendario
              onTap: _onBottomNavTapped,
            ),
          );
        },
      ),
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
            const Text(
              AppStrings.emptySharedMessage,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
              icon: const Icon(Icons.add_link, color: Colors.white),
              label: const Text(
                AppStrings.btnCreaUnisciti,
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => showCalendarManagementModal(context),
            ),
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
              const Text(
                AppStrings.visualeMese,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isShared &&
                  currentCalendar != null &&
                  currentCalendar.inviteCode != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showOtpInfoDialog(
                    currentCalendar!.nome,
                    currentCalendar.inviteCode!,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.priority_high,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Row(
            children: [
              if (isShared && currentCalendar != null) ...[
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.black,
                      size: 20,
                    ),
                    onPressed: () => _confirmDeleteCalendar(
                      currentCalendar!.id,
                      currentCalendar.nome,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
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
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _showSettingsModal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAtmosphereIndicators(int pageCount) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          pageCount,
              (index) => GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _calendarIndex == index
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                boxShadow: _calendarIndex == index
                    ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 10,
                  ),
                ]
                    : [],
              ),
            ),
          ),
        ),
      ),
    );
  }
}