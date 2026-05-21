import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../viewmodels/task_cubit.dart';
import 'glass_task_card.dart';
import 'task_modals.dart';
import 'calendar_management_modal.dart';

class DailyDashboardView extends StatelessWidget {
  final String title;
  final bool isSharedView;
  final String? calendarId;

  const DailyDashboardView({
    super.key,
    required this.title,
    required this.isSharedView,
    required this.calendarId,
  });

  String _getFormattedDateLabel() {
    final now = DateTime.now();
    final giorni = ['Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'];
    final mesi = ['gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', 'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'];
    return "${giorni[now.weekday - 1]} ${now.day} ${mesi[now.month - 1]} ${now.year}";
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
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: isSharedView && calendarId == null
                ? Center(
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
            )
                : BlocBuilder<TaskCubit, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading || state is TaskInitial) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                } else if (state is TaskError) {
                  return Center(child: Text(state.message, style: const TextStyle(color: Colors.redAccent)));
                } else if (state is TaskLoaded) {

                  final now = DateTime.now();
                  // FIX: Conversione a UTC per uniformità con il calendario
                  final targetDayUtc = DateTime.utc(now.year, now.month, now.day);

                  final filteredTasks = state.tasks.where((task) {
                    final parsedDate = DateTime.tryParse(task.dataInizio) ?? now;
                    // FIX: Conversione a UTC per uniformità con il calendario
                    final taskDayUtc = DateTime.utc(parsedDate.year, parsedDate.month, parsedDate.day);

                    final isSameDay = taskDayUtc == targetDayUtc;

                    // FIX: Controllo basato sull'ID invece che sul nome
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
                          Text("Nessun task per oggi.", style: TextStyle(color: Colors.white70, fontSize: 16)),
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
                        // FIX: Controllo basato sull'ID
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