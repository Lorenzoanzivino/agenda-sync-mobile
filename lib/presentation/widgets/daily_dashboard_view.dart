import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/colors.dart';
import '../viewmodels/task_cubit.dart';
import 'glass_task_card.dart';
import 'task_modals.dart';
import 'calendar_management_modal.dart';

class DailyDashboardView extends StatelessWidget {
  final String title;
  final bool isSharedView;
  final String? calendarId;
  final String? inviteCode;

  const DailyDashboardView({
    super.key,
    required this.title,
    required this.isSharedView,
    required this.calendarId,
    this.inviteCode,
  });

  String _getFormattedDateLabel() {
    final now = DateTime.now();
    final giorni = ['Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'];
    final mesi = ['gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', 'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'];
    return "${giorni[now.weekday - 1]} ${now.day} ${mesi[now.month - 1]} ${now.year}";
  }

  void _showOtpInfoDialog(BuildContext context, String calendarName, String code) {
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
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.snackCopiato)));
              Navigator.pop(ctx);
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(_getFormattedDateLabel(), style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              if (isSharedView && calendarId != null && inviteCode != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showOtpInfoDialog(context, title, inviteCode!),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.priority_high, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: isSharedView && calendarId == null
                ? Center(
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
            )
                : BlocBuilder<TaskCubit, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading || state is TaskInitial) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                } else if (state is TaskError) {
                  return Center(child: Text(state.message, style: const TextStyle(color: Colors.redAccent)));
                } else if (state is TaskLoaded) {
                  final now = DateTime.now();
                  final targetDayUtc = DateTime.utc(now.year, now.month, now.day);

                  final filteredTasks = state.tasks.where((task) {
                    final parsedDate = DateTime.tryParse(task.dataInizio) ?? now;
                    final taskDayUtc = DateTime.utc(parsedDate.year, parsedDate.month, parsedDate.day);

                    final isSameDay = taskDayUtc == targetDayUtc;
                    final isTaskShared = task.sharedCalendarId != null;
                    final matchesType = isSharedView ? isTaskShared : !isTaskShared;
                    final matchesCalendar = !isSharedView || task.sharedCalendarId == calendarId;

                    return isSameDay && matchesType && matchesCalendar;
                  }).toList();

                  filteredTasks.sort((a, b) {
                    if (a.tuttoIlGiorno && !b.tuttoIlGiorno) return -1;
                    if (!a.tuttoIlGiorno && b.tuttoIlGiorno) return 1;
                    final dateA = DateTime.tryParse(a.dataInizio) ?? DateTime.now();
                    final dateB = DateTime.tryParse(b.dataInizio) ?? DateTime.now();
                    return dateA.compareTo(dateB);
                  });

                  if (filteredTasks.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.done_all, color: Colors.white24, size: 64),
                          SizedBox(height: 16),
                          Text(AppStrings.nessunTaskOggi, style: TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return GlassTaskCard(
                        title: task.titolo,
                        description: task.descrizione,
                        isShared: task.sharedCalendarId != null,
                        onTap: () => showTaskDetailsModal(context, context.read<TaskCubit>(), task),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}