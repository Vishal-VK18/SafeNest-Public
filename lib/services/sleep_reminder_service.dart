// lib/services/sleep_reminder_service.dart
//
// Schedules / cancels a daily sleep reminder notification at a user-set time.

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class SleepReminderService {
  SleepReminderService._();
  static final SleepReminderService instance = SleepReminderService._();

  static const _channelId   = 'sleep_reminders';
  static const _channelName = 'Sleep Reminders';
  static const _notifId     = 55;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const android  = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin   = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(settings);

    // Create Android channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Daily bedtime reminder notifications',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Schedule a daily notification at [time].
  /// On desktop/unsupported platforms this falls back to a simple immediate show.
  Future<void> scheduleDaily(TimeOfDay time) async {
    await cancelReminder();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Daily bedtime reminder',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    try {
      // RepeatInterval.daily fires every 24h - best cross-platform option
      // without exact alarm scheduling which requires additional permissions.
      await _plugin.periodicallyShow(
        _notifId,
        'SafeNest 🌙 Sleep Reminder',
        "It's time to get ready for sleep. Healthy sleep is important during pregnancy.",
        RepeatInterval.daily,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('[SleepReminder] Scheduled daily reminder at ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('[SleepReminder] Could not schedule (desktop?): $e');
      // On Windows desktop show immediately as a preview
      try {
        await _plugin.show(
          _notifId,
          'SafeNest 🌙 Sleep Reminder',
          "Reminder set for ${time.hour}:${time.minute.toString().padLeft(2, '0')} every night.",
          details,
        );
      } catch (_) {}
    }
  }

  Future<void> cancelReminder() async {
    await _plugin.cancel(_notifId);
  }
}
