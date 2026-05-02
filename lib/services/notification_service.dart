import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service de notifications push — Firebase Cloud Messaging
class NotificationService {
  static final _messaging   = FirebaseMessaging.instance;
  static final _localNotifs = FlutterLocalNotificationsPlugin();

  // ─────────────────────────────────────────────────────────────────────────
  // INITIALISATION
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    // 1. Demander les permissions
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
      provisional: false,
    );
    debugPrint('FCM Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // 2. Configurer les notifications locales (pour foreground)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifs.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 3. Canal Android haute priorité (pour les annonces électorales)
    await _localNotifs
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'maurivote_elections',
          'Élections MauriVote',
          description: 'Notifications des élections en Mauritanie',
          importance: Importance.high,
          playSound: true,
        ));

    // 4. Gérer les messages FCM
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // 5. Abonnement aux topics globaux
    await _messaging.subscribeToTopic('mauritanie_elections');

    // 6. Afficher token FCM en debug
    if (kDebugMode) {
      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Message reçu quand l'app est au premier plan
  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('FCM Foreground: ${message.notification?.title}');
    final notif = message.notification;
    if (notif == null) return;

    await _localNotifs.show(
      message.hashCode,
      notif.title,
      notif.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'maurivote_elections',
          'Élections MauriVote',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF1B5E20),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
        ),
      ),
      payload: message.data['election_id'],
    );
  }

  static void _onNotificationOpenedApp(RemoteMessage message) {
    debugPrint('FCM OpenedApp: ${message.data}');
    // La navigation est gérée dans app.dart via GoRouter
  }

  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ABONNEMENT / DÉSABONNEMENT par élection
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> subscribeToElection(String electionId) async {
    await _messaging.subscribeToTopic('election_$electionId');
    debugPrint('FCM: Abonné à election_$electionId');
  }

  static Future<void> unsubscribeFromElection(String electionId) async {
    await _messaging.unsubscribeFromTopic('election_$electionId');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATIONS LOCALES PROGRAMMÉES (rappels de vote)
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> scheduleVoteReminder({
    required String electionTitle,
    required DateTime dateFermeture,
  }) async {
    // Rappel 1h avant la fermeture
    final reminderTime = dateFermeture.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(DateTime.now())) return;

    debugPrint('FCM: Rappel programmé pour $reminderTime');
    // Note: flutter_local_notifications zonedSchedule nécessite timezone
    // Implémentation complète dans le Sprint 3
  }
}

/// Handler pour les messages en arrière-plan (top-level function obligatoire)
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background: ${message.notification?.title}');
}
