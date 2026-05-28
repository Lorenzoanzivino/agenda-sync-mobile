import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../domain/models/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final NotificationService _notificationService = NotificationService();

  AuthCubit(this._authService) : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      final userDataString = prefs.getString('userData');

      if (token != null && userDataString != null) {
        final Map<String, dynamic> userData = jsonDecode(userDataString);
        userData['token'] = token;
        final user = UserModel.fromJson(userData);

        _setupNotifications();
        emit(AuthAuthenticated(user));
      } else if (token != null) {
        _setupNotifications();
        emit(AuthAuthenticated(UserModel(id: '', email: '', nome: 'Utente')));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authService.login(email, password);
      await _setupNotifications();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(const AuthError('Credenziali non valide. Riprova.'));
    }
  }

  Future<void> signup(
      String nome,
      String email,
      String password,
      String dataNascita,
      ) async {
    emit(AuthLoading());
    try {
      final userWithToken = await _authService.signup(
        nome,
        email,
        password,
        dataNascita,
      );
      await _setupNotifications();
      emit(AuthAuthenticated(userWithToken));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _setupNotifications() async {
    await _notificationService.initNotifications();
    String? fcmToken = await _notificationService.getDeviceToken();
    if (fcmToken != null) {
      try {
        await _authService.updateFcmToken(fcmToken);
      } catch (e) {
        debugPrint("Errore salvataggio fcm token: $e");
      }
    }
  }

  Future<void> updateNotificationTime(String time) async {
    if (state is AuthAuthenticated) {
      try {
        await _authService.updateNotificationTime(time);

        final currentUser = (state as AuthAuthenticated).user;
        final updatedUser = currentUser.copyWith(orarioNotificaMattutina: time);

        final prefs = await SharedPreferences.getInstance();
        final userDataString = prefs.getString('userData');
        if (userDataString != null) {
          final Map<String, dynamic> userData = jsonDecode(userDataString);
          userData['orarioNotificaMattutina'] = time;
          await prefs.setString('userData', jsonEncode(userData));
        }

        emit(AuthAuthenticated(updatedUser));
      } catch (e) {
        debugPrint("Errore aggiornamento orario notifica: $e");
      }
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    await _authService.logout();
    emit(AuthUnauthenticated());
  }
}