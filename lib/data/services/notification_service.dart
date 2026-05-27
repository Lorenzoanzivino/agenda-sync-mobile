import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

// Funzione isolata (top-level) OBBLIGATORIA per elaborare le notifiche quando l'app è in background o chiusa
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Richiesto da Firebase per far funzionare l'isolate in background
  await Firebase.initializeApp();
  debugPrint('🌙 Ricevuta notifica in Background: ${message.notification?.title}');
}

class NotificationService {
  static final StreamController<void> onNotificationReceived =
  StreamController.broadcast();

  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool get _isFirebaseSupported {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  Future<void> initNotifications() async {
    if (!_isFirebaseSupported) {
      debugPrint(
        '⚠️ Ambiente Linux/Windows: Skip inizializzazione Firebase Messaging.',
      );
      return;
    }

    try {
      // Registrazione dell'handler per le notifiche in background
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Richiesta permessi nativi
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Permessi notifiche concessi.');
      } else {
        debugPrint('⚠️ Permessi notifiche negati.');
      }

      // Configurazione canale di notifica per Android
      const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(
        android: androidInitSettings,
      );
      await _localNotificationsPlugin.initialize(initSettings);

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'Notifiche Importanti',
        description:
        'Canale utilizzato per notifiche push immediate (es. nuovi task).',
        importance: Importance.max,
      );

      if (Platform.isAndroid) {
        await _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
        >()
            ?.createNotificationChannel(channel);
      }

      // Consenti a iOS di mostrare notifiche in Foreground automaticamente
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listener per l'App in Foreground (Schermo acceso sull'app)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '📥 Ricevuta notifica in Foreground: ${message.notification?.title}',
        );

        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        // Se la notifica contiene testo, forza il banner a schermo tramite pacchetto locale
        if (notification != null && android != null && !kIsWeb) {
          _localNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
                color: const Color(0xFF06B6D4), // Cyan Accent per l'icona
              ),
            ),
          );
        }

        // Segnale per far aggiornare il TableCalendar in tempo reale
        onNotificationReceived.add(null);
      });
    } catch (e) {
      debugPrint('❌ Errore inizializzazione Firebase Messaging: $e');
    }
  }

  Future<String?> getDeviceToken() async {
    if (!_isFirebaseSupported) {
      return "fake_token_for_desktop_testing";
    }

    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token Rigenerato: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Errore recupero FCM Token: $e');
      return null;
    }
  }
}