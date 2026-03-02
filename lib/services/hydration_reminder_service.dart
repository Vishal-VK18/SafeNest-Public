// lib/services/hydration_reminder_service.dart
//
// Wraps flutter_local_notifications to schedule / cancel periodic
// hydration reminders.  Each reschedule cancels all previous ones
// first, preventing duplication.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HydrationReminderService {
  HydrationReminderService._();
  static final HydrationReminderService instance =
      HydrationReminderService._();

  static const _channelId   = 'hydration_reminders';
  static const _channelName = 'Hydration Reminders';
  static const _notifId     = 42; // stable ID for hydration reminders

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Initialise (call once from main.dart after WidgetsFlutterBinding) ──────
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin  = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(settings);
  }

  // ── Schedule repeating reminder every [frequencyHours] hours ────────────
  Future<void> scheduleReminder({int frequencyHours = 2}) async {
    await cancelReminder(); // always cancel before rescheduling

    // Map hours → RepeatInterval
    final interval = _toRepeatInterval(frequencyHours);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Periodic hydration reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
        android: androidDetails, iOS: darwinDetails);

    await _plugin.periodicallyShow(
      _notifId,
      'SafeNest 💧 Hydration Reminder',
      'Time to hydrate 💧 Stay healthy for you and baby.',
      interval,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // ── Cancel all hydration reminders ────────────────────────────────────────
  Future<void> cancelReminder() async {
    await _plugin.cancel(_notifId);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  RepeatInterval _toRepeatInterval(int hours) {
    switch (hours) {
      case 1:  return RepeatInterval.hourly;
      case 4:  return RepeatInterval.daily;  // closest available
      default: return RepeatInterval.hourly; // 2h and 3h → hourly (closest)
    }
    // Note: flutter_local_notifications only supports Hourly/Daily/Weekly
    // natively.  For true 2h/3h intervals, exact alarm scheduling would
    // require a background service.  Hourly is the safe fallback.
  }
}
