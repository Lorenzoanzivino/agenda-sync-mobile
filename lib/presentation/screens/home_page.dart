import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/models/shared_calendar_model.dart';
import '../widgets/atmosphere_background.dart';
import '../widgets/daily_dashboard_view.dart';
import '../widgets/task_modals.dart';
import '../widgets/calendar_management_modal.dart';
import '../viewmodels/auth_cubit.dart';
import '../viewmodels/auth_state.dart';
import '../viewmodels/task_cubit.dart';
import '../viewmodels/calendar_cubit.dart';
import 'calendar_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  late int _dashboardIndex;
  String _preferredNotificationTime = "08:00";
  bool _hasFetched = false;

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  List<SharedCalendarModel> _cachedCalendars = [];

  @override
  void initState() {
    super.initState();
    _dashboardIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadNotificationTimeForCurrentContext();
  }

  String get _currentContextKey {
    if (_dashboardIndex == 0 || _cachedCalendars.isEmpty) {
      return 'notification_time_private';
    }
    int sharedIdx = _dashboardIndex - 1;
    if (sharedIdx >= _cachedCalendars.length) {
      sharedIdx = _cachedCalendars.length - 1;
    }
    return 'notification_time_shared_${_cachedCalendars[sharedIdx].id}';
  }

  Future<void> _loadNotificationTimeForCurrentContext() async {
    String? savedTime = await _storage.read(key: _currentContextKey);
    if (savedTime != null) {
      setState(() {
        _preferredNotificationTime = savedTime;
      });
    } else {
      setState(() {
        _preferredNotificationTime = "08:00";
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetched) {
      context.read<TaskCubit>().fetchTasks();
      context.read<CalendarCubit>().fetchSharedCalendars();
      _hasFetched = true;
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CalendarPage(initialIndex: _dashboardIndex),
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
                      onChanged: (val) async {
                        if (val != null) {
                          setState(() => _preferredNotificationTime = val);
                          await _storage.write(key: _currentContextKey, value: val);

                          // Se siamo nel privato, aggiorniamo anche sul profilo utente globale se desiderato
                          if (_dashboardIndex == 0) {
                            context.read<AuthCubit>().updateNotificationTime(val);
                          }

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
              if (totalShared > 1 && _dashboardIndex == totalShared) {
                _pageController.animateToPage(
                  _dashboardIndex - 1,
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
          bool isShared = _dashboardIndex > 0;

          Color currentBgColor = AppAtmospheres.privateBg;
          List<Color> currentCircles = AppAtmospheres.privateCircles;

          if (isShared && _cachedCalendars.isNotEmpty) {
            int sharedIdx = _dashboardIndex - 1;
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
                          onPageChanged: (index) {
                            setState(() => _dashboardIndex = index);
                            _loadNotificationTimeForCurrentContext();
                          },
                          itemCount: pageCount,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return const DailyDashboardView(
                                title: AppStrings.dashboardPrivata,
                                isSharedView: false,
                                calendarId: null,
                                inviteCode: null,
                              );
                            } else {
                              if (_cachedCalendars.isEmpty) {
                                return const DailyDashboardView(
                                  title: AppStrings.calendarioCondivisoDefault,
                                  isSharedView: true,
                                  calendarId: null,
                                  inviteCode: null,
                                );
                              } else {
                                int calendarIndex = index - 1;
                                if (calendarIndex >= _cachedCalendars.length) {
                                  calendarIndex = _cachedCalendars.length - 1;
                                }
                                final calendar =
                                _cachedCalendars[calendarIndex];
                                return DailyDashboardView(
                                  title: calendar.nome,
                                  isSharedView: true,
                                  calendarId: calendar.id,
                                  inviteCode: calendar.inviteCode,
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
            bottomNavigationBar: _buildCustomBottomNav(),
          );
        },
      ),
    );
  }

  Widget _buildHeaderBar(bool isShared) {
    SharedCalendarModel? currentCalendar;
    if (isShared && _cachedCalendars.isNotEmpty) {
      int sharedIdx = _dashboardIndex - 1;
      if (sharedIdx >= 0 && sharedIdx < _cachedCalendars.length) {
        currentCalendar = _cachedCalendars[sharedIdx];
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              String userName = "Utente";
              if (state is AuthAuthenticated) {
                try {
                  userName = state.user.nome;
                } catch (_) {}
              }
              return Text(
                "${AppStrings.ciao} $userName",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
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
                    icon: const Icon(Icons.delete_outline, color: Colors.black),
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
                  icon: const Icon(Icons.add, color: Colors.black),
                  onPressed: () {
                    if (isShared && _cachedCalendars.isEmpty) {
                      showCalendarManagementModal(context);
                    } else {
                      showTaskFormModal(
                        context,
                        context.read<TaskCubit>(),
                        isShared: isShared,
                        forcedCalendarId: currentCalendar?.id,
                        forcedDate: DateTime.now(),
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

  Widget _buildAtmosphereIndicators(int pageCount) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 10),
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
                color: _dashboardIndex == index
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                boxShadow: _dashboardIndex == index
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

  Widget _buildCustomBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            border: const Border(
              top: BorderSide(color: Colors.white10, width: 0.5),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.dashboard_rounded, AppStrings.navHome, 0),
                  _buildNavItem(
                    Icons.calendar_month_rounded,
                    AppStrings.navCalendario,
                    1,
                  ),
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
    bool isSelected = index == 0;
    return GestureDetector(
      onTap: () => _onBottomNavTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white54),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}