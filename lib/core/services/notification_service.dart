import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Handles FCM push notification setup and token management.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Request permission and save FCM token to user doc.
  Future<void> init(String userId) async {
    // Request permission (web & iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get and save token
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(userId, token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _saveToken(userId, newToken);
      });
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    await _db.collection('users').doc(userId).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  /// Listen for foreground messages and show a SnackBar
  void listenForeground(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (body.isNotEmpty) Text(body, style: const TextStyle(fontSize: 12)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    });
  }

  /// Handle notification taps when app was in background
  void handleBackgroundTaps(void Function(String? route) onTap) {
    // App opened from terminated state
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        onTap(message.data['route'] as String?);
      }
    });

    // App opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onTap(message.data['route'] as String?);
    });
  }
}
