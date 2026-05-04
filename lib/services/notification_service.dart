import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      await _messaging.subscribeToTopic("mauritanie_elections");
      if (kDebugMode) {
        final token = await _messaging.getToken();
        debugPrint("FCM Token: $token");
      }
      FirebaseMessaging.onBackgroundMessage(_bgHandler);
    } catch (e) {
      debugPrint("NotificationService error: $e");
    }
  }

  static Future<void> subscribeToElection(String id) async {
    await _messaging.subscribeToTopic("election_$id");
  }
}

@pragma("vm:entry-point")
Future<void> _bgHandler(RemoteMessage message) async {
  debugPrint("FCM bg: ${message.notification?.title}");
}