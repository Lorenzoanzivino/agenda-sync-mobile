import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/models/task_model.dart';
import '../viewmodels/task_cubit.dart';
import '../viewmodels/calendar_cubit.dart';
import 'glass_task_card.dart';
import 'task_modals.dart';

void showDayAgendaModal(
    BuildContext context,
    DateTime day,
    List<TaskModel> tasks,
    Color bgColor,
    bool isSharedView,
    String? calendarId,
    ) {
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
          child: DayAgendaModalContent(
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

class DayAgendaModalContent extends StatefulWidget {
  final DateTime day;
  final List<TaskModel> initialTasks;
  final Color bgColor;
  final bool isSharedView;
  final String? calendarId;

  const DayAgendaModalContent({
    super.key,
    required this.day,
    required this.initialTasks,
    required this.bgColor,
    required this.isSharedView,
    required this.calendarId,
  });

  @override
  State<DayAgendaModalContent> createState() => _DayAgendaModalContentState();
}

class _DayAgendaModalContentState extends State<DayAgendaModalContent> {
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
          final targetDayUtc = DateTime.utc(
            widget.day.year,
            widget.day.month,
            widget.day.day,
          );
          tasks = state.tasks.where((task) {
            final parsedDate =
                DateTime.tryParse(task.dataInizio) ?? DateTime.now();
            final taskDayUtc = DateTime.utc(
              parsedDate.year,
              parsedDate.month,
              parsedDate.day,
            );

            final isSameDay = taskDayUtc == targetDayUtc;
            final isTaskShared = task.sharedCalendarId != null;
            final matchesType = widget.isSharedView
                ? isTaskShared
                : !isTaskShared;
            final matchesCalendar =
                !widget.isSharedView ||
                    task.sharedCalendarId == widget.calendarId;

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
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
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
                        context.read<TaskCubit>().bulkDeleteTasks(
                          List<String>.from(_selectedTaskIds),
                        );
                        _exitSelectionMode();
                      },
                      icon: const Icon(
                        Icons.delete_sweep,
                        color: Colors.redAccent,
                      ),
                      label: Text(
                        "Elimina (${_selectedTaskIds.length})",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(width: 40),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 28,
                    ),
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
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                "${AppStrings.agendaDel} ${widget.day.day.toString().padLeft(2, '0')}/${widget.day.month.toString().padLeft(2, '0')}/${widget.day.year}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: tasks.isEmpty
                    ? const Center(
                  child: Text(
                    AppStrings.nessunTaskData,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
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
                          showTaskDetailsModal(
                            context,
                            context.read<TaskCubit>(),
                            task,
                          );
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