import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/shared_calendar_model.dart';

class CalendarService {
  final ApiClient _apiClient = ApiClient();

  Future<List<SharedCalendarModel>> getMySharedCalendars() async {
    debugPrint("📤 Richiesta GET a /calendars/shared");
    final response = await _apiClient.get('/calendars/shared');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SharedCalendarModel.fromJson(json)).toList();
    } else {
      throw Exception('Impossibile caricare i calendari condivisi.');
    }
  }

  Future<SharedCalendarModel> createSharedCalendar(String nome) async {
    final payload = {"nome": nome};
    debugPrint("📤 Richiesta POST a /calendars/shared. Payload: $payload");

    final response = await _apiClient.post('/calendars/shared', payload);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return SharedCalendarModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Errore durante la creazione del calendario.');
    }
  }

  Future<void> joinSharedCalendar(String inviteCode) async {
    final payload = {"inviteCode": inviteCode};
    debugPrint("📤 Richiesta POST a /calendars/shared/join. Payload: $payload");

    final response = await _apiClient.post('/calendars/shared/join', payload);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Codice non valido o errore di connessione.');
    }
  }
}