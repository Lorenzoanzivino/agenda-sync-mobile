import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/colors.dart';
import '../widgets/atmosphere_background.dart';
import '../widgets/daily_dashboard_view.dart';
import '../widgets/task_modals.dart';
import '../widgets/calendar_management_modal.dart';
import '../viewmodels/auth_cubit.dart';
import '../viewmodels/task_cubit.dart';
import '../viewmodels/calendar_cubit.dart';
import 'calendar_page.dart';

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

  @override
  void initState() {
    super.initState();
    _dashboardIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Assicuriamoci che i calendari siano caricati all'avvio
    context.read<TaskCubit>().fetchTasks();
    context.read<CalendarCubit>().fetchSharedCalendars();
  }

  void _onBottomNavTapped(int index) {
    if (index == 1) {
      // Passa l'indice corrente al Calendario
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CalendarPage(initialIndex: _dashboardIndex)));
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
    bool isShared = _dashboardIndex == 1;

    return Scaffold(
      extendBody: true,
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
                    onPageChanged: (index) => setState(() => _dashboardIndex = index),
                    children: const [
                      DailyDashboardView(title: "Dashboard Privata", isSharedView: false),
                      DailyDashboardView(title: "Calendario Condiviso", isSharedView: true),
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
          const Text("Ciao Lorenzo", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    // Controlliamo se ci sono calendari prima di aprire il modal nel contesto condiviso
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

  Widget _buildAtmosphereIndicators() {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 10),
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
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _dashboardIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.3),
                boxShadow: _dashboardIndex == index ? [BoxShadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 10)] : []
            ),
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
    bool isSelected = index == 0;
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