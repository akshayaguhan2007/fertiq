import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _local = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'cropplus_high', 'CROP+ Alerts',
    description: 'Satellite data, carbon credits, soil and weather alerts',
    importance: Importance.high,
  );

  Future<void> init({required GoRouter router}) async {
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) router.go(details.payload!);
      },
    );
  }

  Future<void> showAlert({
    required String title,
    required String body,
    String? route,
  }) async {
    try {
      await _local.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title, body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id, _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high, priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: route,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Notification error: $e');
    }
  }
}
