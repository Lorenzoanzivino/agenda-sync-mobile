import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/services/task_service.dart';
import '../../../domain/models/task_model.dart';

abstract class TaskState extends Equatable {
  const TaskState();
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}
class TaskLoading extends TaskState {}
class TaskLoaded extends TaskState {
  final List<TaskModel> tasks;
  const TaskLoaded(this.tasks);
  @override
  List<Object?> get props => [tasks];
}
class TaskError extends TaskState {
  final String message;
  const TaskError(this.message);
  @override
  List<Object?> get props => [message];
}

class TaskCubit extends Cubit<TaskState> {
  final TaskService _taskService;

  TaskCubit(this._taskService) : super(TaskInitial());

  List<TaskModel> _sortTasks(List<TaskModel> tasks) {
    final sorted = List<TaskModel>.from(tasks);
    sorted.sort((a, b) {
      final dateA = DateTime.tryParse(a.dataInizio) ?? DateTime.now();
      final dateB = DateTime.tryParse(b.dataInizio) ?? DateTime.now();
      return dateA.compareTo(dateB);
    });
    return sorted;
  }

  Future<void> fetchTasks() async {
    emit(TaskLoading());
    try {
      final tasks = await _taskService.getTasks();
      emit(TaskLoaded(tasks));
    } catch (e, stacktrace) {
      debugPrint("❌ ERRORE IN fetchTasks: $e");
      debugPrint("$stacktrace");
      emit(TaskError(e.toString()));
    }
  }

  Future<void> createTask({
    required String titolo,
    required String descrizione,
    required DateTime dataInizio,
    required DateTime dataFine,
    required String priorita,
    required bool tuttoIlGiorno,
    String? sharedCalendarId,
  }) async {
    try {
      debugPrint("⏳ Avvio creazione task...");
      final newTask = await _taskService.createTask(
        titolo: titolo,
        descrizione: descrizione,
        dataInizio: dataInizio,
        dataFine: dataFine,
        priorita: priorita,
        tuttoIlGiorno: tuttoIlGiorno,
        sharedCalendarId: sharedCalendarId,
      );
      debugPrint("✅ Task creato con successo nel Cubit: ${newTask.id}");

      if (state is TaskLoaded) {
        final currentTasks = (state as TaskLoaded).tasks;
        final updatedList = List<TaskModel>.from(currentTasks)..add(newTask);
        emit(TaskLoaded(_sortTasks(updatedList)));
      } else {
        fetchTasks();
      }
    } catch (e, stacktrace) {
      debugPrint("❌ CRASH IN createTask: $e");
      debugPrint("$stacktrace");
      fetchTasks();
    }
  }

  Future<void> updateTask(String id, {
    required String titolo,
    required String descrizione,
    required DateTime dataInizio,
    required DateTime dataFine,
    required String priorita,
    required bool tuttoIlGiorno,
    String? sharedCalendarId,
  }) async {
    try {
      final updatedTask = await _taskService.updateTask(
        id,
        titolo: titolo,
        descrizione: descrizione,
        dataInizio: dataInizio,
        dataFine: dataFine,
        priorita: priorita,
        tuttoIlGiorno: tuttoIlGiorno,
        sharedCalendarId: sharedCalendarId,
      );
      if (state is TaskLoaded) {
        final tasks = (state as TaskLoaded).tasks.map((t) => t.id == id ? updatedTask : t).toList();
        emit(TaskLoaded(_sortTasks(tasks)));
      } else {
        fetchTasks();
      }
    } catch (e, stacktrace) {
      debugPrint("❌ CRASH IN updateTask: $e");
      debugPrint("$stacktrace");
      fetchTasks();
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _taskService.deleteTask(id);
      if (state is TaskLoaded) {
        final tasks = (state as TaskLoaded).tasks.where((t) => t.id != id).toList();
        emit(TaskLoaded(tasks));
      } else {
        fetchTasks();
      }
    } catch (e, stacktrace) {
      debugPrint("❌ CRASH IN deleteTask: $e");
      debugPrint("$stacktrace");
      fetchTasks();
    }
  }
}