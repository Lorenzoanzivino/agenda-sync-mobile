import 'dart:convert';
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
        final userData = jsonDecode(userDataString);
        final user = UserModel.fromJson(userData);

        _setupNotifications();
        emit(AuthAuthenticated(user));
      } else if (token != null) {
        // Fallback di sicurezza se esiste token ma non i dati
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
        // Log silenzioso se fallisce l'update del token
      }
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    await _authService.logout();
    emit(AuthUnauthenticated());
  }
}