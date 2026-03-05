// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // ─── Init ────────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission:  true,
      requestBadgePermission:  true,
      requestSoundPermission:  true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS:     iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Create Android notification channel for high-importance alerts
    const channel = AndroidNotificationChannel(
      'safenest_alerts',
      'SafeNest Alerts',
      description:  'Health and safety alerts from your SafeNest wearable',
      importance:   Importance.max,
      playSound:    true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ─── Private helper ──────────────────────────────────────────────────────────
  static Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'safenest_alerts',
      'SafeNest Alerts',
      channelDescription: 'Health and safety alerts',
      importance:         Importance.max,
      priority:           Priority.max,
      fullScreenIntent:   true,
      category:           AndroidNotificationCategory.alarm,
      playSound:          true,
      enableVibration:    true,
      visibility:         NotificationVisibility.public,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS:     iosDetails,
    );

    try {
      await _plugin.show(id, title, body, details);
    } catch (e) {
      debugPrint('[Notification] Error: $e');
    }
  }

  // ─── Alert types ─────────────────────────────────────────────────────────────
  static Future<void> showFallAlert() => _show(
    id:    AppConstants.notifIdFall,
    title: '⚠️ Fall Detected!',
    body:  'A sudden fall was detected. Emergency contacts will be notified shortly.',
  );

  static Future<void> showAbnormalHeartRate(int bpm) => _show(
    id:    AppConstants.notifIdHeartRate,
    title: '❤️ Abnormal Heart Rate',
    body:  'Heart rate is $bpm BPM — outside the safe range. Please check on the wearer.',
  );

  static Future<void> showHighTemperature(double temp) => _show(
    id:    AppConstants.notifIdTemperature,
    title: '🌡️ High Body Temperature',
    body:  'Temperature is ${temp.toStringAsFixed(1)}°C — above 38°C threshold.',
  );

  static Future<void> showLowTemperature(double temp) => _show(
    id:    AppConstants.notifIdLowTemperature,
    title: '❄️ Low Body Temperature',
    body:  'Temperature is ${temp.toStringAsFixed(1)}°C — below 35°C threshold.',
  );

  static Future<void> showDeviceDisconnected(String deviceName) => _show(
    id:    AppConstants.notifIdDisconnect,
    title: '📡 Device Disconnected',
    body:  '$deviceName has lost connection. Attempting to reconnect...',
  );

  static Future<void> showSimError() => _show(
    id:    AppConstants.notifIdSimError,
    title: '🔴 SIM Module Error',
    body:  'The SIM communication unit is unreachable. Emergency SMS alerts may not work.',
  );

  static Future<void> cancelAll() => _plugin.cancelAll();
}
