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
  String _preferredNotificationTime = "Nessuna";
  bool _hasFetched = false;

  final _storage = const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
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
    if (sharedIdx >= _cachedCalendars.length) sharedIdx = _cachedCalendars.length - 1;
    return 'notification_time_shared_${_cachedCalendars[sharedIdx].id}';
  }

  Future<void> _loadNotificationTimeForCurrentContext() async {
    String? savedTime = await _storage.read(key: _currentContextKey);
    if (!mounted) return;
    setState(() {
      _preferredNotificationTime = savedTime ?? "Nessuna";
    });
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CalendarPage(initialIndex: _dashboardIndex)));
    } else if (index == 2) {
      context.read<AuthCubit>().logout();
    }
  }

  void _showSettingsModal() {
    final List<String> briefingTimes = ["Nessuna"];
    for (int h = 1; h <= 24; h++) {
      briefingTimes.add('${h.toString().padLeft(2, '0')}:00');
      if (h < 24) briefingTimes.add('${h.toString().padLeft(2, '0')}:30');
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
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.impostazioni, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text("Sveglia Promemoria Impegni:", style: TextStyle(color: Colors.white70, fontSize: 16)),
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
                      items: briefingTimes.map((String time) => DropdownMenuItem<String>(value: time, child: Text(time))).toList(),
                      onChanged: (val) async {
                        if (val != null) {
                          await _storage.write(key: _currentContextKey, value: val);
                          if (!ctx.mounted) return;
                          setState(() => _preferredNotificationTime = val);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Sveglia aggiornata a: $val"), backgroundColor: Colors.green),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 50,
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
        }
      },
      child: BlocBuilder<CalendarCubit, CalendarState>(
        builder: (context, state) {
          if (state is CalendarLoaded) _cachedCalendars = state.sharedCalendars;

          int pageCount = _cachedCalendars.isEmpty ? 2 : _cachedCalendars.length + 1;
          bool isShared = _dashboardIndex > 0;

          Color currentBgColor = AppAtmospheres.privateBg;
          List<Color> currentCircles = AppAtmospheres.privateCircles;

          if (isShared && _cachedCalendars.isNotEmpty) {
            int sharedIdx = _dashboardIndex - 1;
            if (sharedIdx >= _cachedCalendars.length) sharedIdx = _cachedCalendars.length - 1;
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
                AtmosphereBackground(backgroundColor: currentBgColor, circleColors: currentCircles),
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, state) {
                                String userName = "Utente";
                                if (state is AuthAuthenticated) userName = state.user.nome;
                                return Text("${AppStrings.ciao} $userName", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold));
                              },
                            ),
                            Row(
                              children: [
                                Container(
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: IconButton(
                                    icon: const Icon(Icons.add, color: Colors.black),
                                    onPressed: () {
                                      showTaskFormModal(
                                        context,
                                        context.read<TaskCubit>(),
                                        isShared: isShared,
                                        forcedCalendarId: isShared && _cachedCalendars.isNotEmpty ? _cachedCalendars[_dashboardIndex - 1].id : null,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                                  child: IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _showSettingsModal),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
                              return const DailyDashboardView(title: AppStrings.dashboardPrivata, isSharedView: false, calendarId: null);
                            } else {
                              final calendar = _cachedCalendars.isNotEmpty ? _cachedCalendars[index - 1] : null;
                              return DailyDashboardView(
                                title: calendar?.nome ?? AppStrings.calendarioCondivisoDefault,
                                isSharedView: true,
                                calendarId: calendar?.id,
                                inviteCode: calendar?.inviteCode,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), border: const Border(top: BorderSide(color: Colors.white10, width: 0.5))),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                              child: const Row(children: [Icon(Icons.dashboard_rounded, color: Colors.white), SizedBox(width: 8), Text('Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _onBottomNavTapped(1),
                            child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.calendar_month_rounded, color: Colors.white54)),
                          ),
                          GestureDetector(
                            onTap: () => _onBottomNavTapped(2),
                            child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.logout_rounded, color: Colors.white54)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}