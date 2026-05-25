import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../domain/models/task_model.dart';

class TaskService {
  final ApiClient _apiClient = ApiClient();

  Future<List<TaskModel>> getTasks() async {
    final response = await _apiClient.get('/tasks');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TaskModel.fromJson(json)).toList();
    } else {
      throw Exception('Impossibile caricare i task. Status: ${response.statusCode}');
    }
  }

  Future<TaskModel> createTask({
    required String titolo,
    required String descrizione,
    required DateTime dataInizio,
    required DateTime dataFine,
    required String colore,
    String priorita = 'LOW',
    bool tuttoIlGiorno = false,
    String? sharedCalendarId,
  }) async {
    final payload = <String, dynamic>{
      "titolo": titolo,
      "descrizione": descrizione,
      "dataInizio": dataInizio.toIso8601String(),
      "dataFine": dataFine.toIso8601String(),
      "tuttoIlGiorno": tuttoIlGiorno,
      "colore": colore,
      "priorita": priorita,
      "status": "TODO"
    };

    if (sharedCalendarId != null) {
      payload["sharedCalendarId"] = sharedCalendarId;
    }

    final response = await _apiClient.post('/tasks', payload);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return TaskModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Errore creazione task: ${response.statusCode}');
    }
  }

  Future<TaskModel> updateTask(String id, {
    required String titolo,
    required String descrizione,
    required DateTime dataInizio,
    required DateTime dataFine,
    required String colore,
    String priorita = 'LOW',
    bool tuttoIlGiorno = false,
    String? sharedCalendarId,
  }) async {
    final payload = <String, dynamic>{
      "titolo": titolo,
      "descrizione": descrizione,
      "dataInizio": dataInizio.toIso8601String(),
      "dataFine": dataFine.toIso8601String(),
      "tuttoIlGiorno": tuttoIlGiorno,
      "colore": colore,
      "priorita": priorita,
      "status": "TODO"
    };

    if (sharedCalendarId != null) {
      payload["sharedCalendarId"] = sharedCalendarId;
    }

    final response = await _apiClient.put('/tasks/$id', payload);
    if (response.statusCode == 200) {
      return TaskModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Errore aggiornamento task. Status: ${response.statusCode}');
    }
  }

  Future<void> deleteTask(String id) async {
    final response = await _apiClient.delete('/tasks/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Impossibile eliminare il task. Status: ${response.statusCode}');
    }
  }

  Future<void> bulkDeleteTasks(List<String> ids) async {
    final payload = <String, dynamic>{
      "taskIds": ids
    };

    final response = await _apiClient.post('/tasks/bulk-delete', payload);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Errore cancellazione massiva. Status: ${response.statusCode}');
    }
  }
}