import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  // Getter lazy: non viene chiamato finché non serve, evitando crash all'avvio
  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;

  // Verifica se la piattaforma supporta Firebase Messaging
  bool get _isFirebaseSupported {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  Future<void> initNotifications() async {
    if (!_isFirebaseSupported) {
      debugPrint('⚠️ Ambiente Linux/Windows: Skip inizializzazione Firebase Messaging.');
      return;
    }

    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Permessi notifiche concessi.');
      } else {
        debugPrint('⚠️ Permessi notifiche negati.');
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📥 Ricevuta notifica in Foreground: ${message.notification?.title}');
      });
    } catch (e) {
      debugPrint('❌ Errore inizializzazione Firebase Messaging: $e');
    }
  }

  Future<String?> getDeviceToken() async {
    if (!_isFirebaseSupported) {
      debugPrint('⚠️ Ambiente Linux/Windows: Generato FCM Token fake per testing.');
      return "fake_token_for_desktop_testing";
    }

    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Errore recupero FCM Token: $e');
      return null;
    }
  }
}