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