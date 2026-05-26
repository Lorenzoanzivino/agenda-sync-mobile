import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../domain/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<UserModel> login(String email, String password) async {
    final response = await _apiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data);

      if (user.token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userToken', user.token!);
      }
      return user;
    } else {
      throw Exception('Credenziali non valide o errore server');
    }
  }

  Future<UserModel> signup(
    String nome,
    String email,
    String password,
    String dataNascita,
  ) async {
    final response = await _apiClient.post('/auth/signup', {
      'nome': nome,
      'email': email,
      'password': password,
      'dataNascita': dataNascita,
    });

    // Spring Boot restituisce 201 Created in caso di successo
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data);

      if (user.token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userToken', user.token!);
      }
      return user;
    } else {
      // Potresti decodificare il body per leggere il messaggio di errore specifico
      throw Exception('Registrazione fallita. Verifica i dati inseriti.');
    }
  }

  // Nuova funzione per salvare l'FCM Token
  Future<void> updateFcmToken(String fcmToken) async {
    // Assicurati che l'endpoint coincida con il tuo Controller Spring Boot
    await _apiClient.put('/users/fcm-token', {'fcmToken': fcmToken});
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');
  }
}
