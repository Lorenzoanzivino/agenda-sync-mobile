import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/services/calendar_service.dart';
import '../../../domain/models/shared_calendar_model.dart';

abstract class CalendarState extends Equatable {
  const CalendarState();
  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarState {}
class CalendarLoading extends CalendarState {}
class CalendarLoaded extends CalendarState {
  final List<SharedCalendarModel> sharedCalendars;
  const CalendarLoaded(this.sharedCalendars);
  @override
  List<Object?> get props => [sharedCalendars];
}
class CalendarActionSuccess extends CalendarState {
  final String message;
  final String? codeToShow;
  const CalendarActionSuccess(this.message, {this.codeToShow});
  @override
  List<Object?> get props => [message, codeToShow];
}
class CalendarError extends CalendarState {
  final String message;
  const CalendarError(this.message);
  @override
  List<Object?> get props => [message];
}

class CalendarCubit extends Cubit<CalendarState> {
  final CalendarService _calendarService;

  CalendarCubit(this._calendarService) : super(CalendarInitial());

  Future<void> fetchSharedCalendars() async {
    emit(CalendarLoading());
    try {
      final list = await _calendarService.getMySharedCalendars();
      emit(CalendarLoaded(list));
    } catch (e, stacktrace) {
      debugPrint("❌ ERRORE IN fetchSharedCalendars: $e\n$stacktrace");
      emit(CalendarError(e.toString()));
    }
  }

  Future<void> createCalendar(String nome) async {
    emit(CalendarLoading());
    try {
      final newCalendar = await _calendarService.createSharedCalendar(nome);
      emit(CalendarActionSuccess(
          "Calendario creato con successo!",
          codeToShow: newCalendar.inviteCode
      ));
      fetchSharedCalendars(); // Aggiorna la lista
    } catch (e, stacktrace) {
      debugPrint("❌ ERRORE IN createCalendar: $e\n$stacktrace");
      emit(CalendarError(e.toString()));
      fetchSharedCalendars();
    }
  }

  Future<void> joinCalendar(String inviteCode) async {
    emit(CalendarLoading());
    try {
      await _calendarService.joinSharedCalendar(inviteCode);
      emit(const CalendarActionSuccess("Ti sei unito al calendario con successo!"));
      fetchSharedCalendars(); // Aggiorna la lista
    } catch (e, stacktrace) {
      debugPrint("❌ ERRORE IN joinCalendar: $e\n$stacktrace");
      emit(CalendarError(e.toString()));
      fetchSharedCalendars();
    }
  }
}