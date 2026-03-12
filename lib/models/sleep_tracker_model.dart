// lib/models/sleep_tracker_model.dart
import 'package:flutter/material.dart';

enum SleepTrackingStatus { idle, tracking, paused }

class SleepSession {
  final DateTime startTime;
  final DateTime endTime;

  SleepSession({required this.startTime, required this.endTime});

  Duration get totalSleep => endTime.difference(startTime);
  Duration get deepSleep => Duration(minutes: (totalSleep.inMinutes * 0.45).round());
  Duration get lightSleep => totalSleep - deepSleep;
  double get quality => (totalSleep.inHours / 8.0).clamp(0.0, 1.0);
  int get qualityScore => (quality * 100).round();

  String get qualityLabel {
    if (qualityScore >= 85) return 'Excellent';
    if (qualityScore >= 70) return 'Good';
    if (qualityScore >= 50) return 'Fair';
    return 'Poor';
  }

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
  };

  factory SleepSession.fromJson(Map<String, dynamic> json) => SleepSession(
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: DateTime.parse(json['endTime'] as String),
  );
}

class SleepReminderSettings {
  final bool enabled;
  final TimeOfDay reminderTime;

  const SleepReminderSettings({
    this.enabled = false,
    this.reminderTime = const TimeOfDay(hour: 22, minute: 0),
  });

  SleepReminderSettings copyWith({bool? enabled, TimeOfDay? reminderTime}) =>
      SleepReminderSettings(
        enabled: enabled ?? this.enabled,
        reminderTime: reminderTime ?? this.reminderTime,
      );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'hour': reminderTime.hour,
    'minute': reminderTime.minute,
  };

  factory SleepReminderSettings.fromJson(Map<String, dynamic> json) =>
      SleepReminderSettings(
        enabled: json['enabled'] as bool? ?? false,
        reminderTime: TimeOfDay(
          hour: json['hour'] as int? ?? 22,
          minute: json['minute'] as int? ?? 0,
        ),
      );
}

class SleepTrackerState {
  final SleepTrackingStatus status;
  final DateTime? sessionStart;
  final List<SleepSession> history; // last 7 days
  final SleepReminderSettings reminder;

  const SleepTrackerState({
    this.status = SleepTrackingStatus.idle,
    this.sessionStart,
    this.history = const [],
    this.reminder = const SleepReminderSettings(),
  });

  SleepTrackerState copyWith({
    SleepTrackingStatus? status,
    DateTime? sessionStart,
    List<SleepSession>? history,
    SleepReminderSettings? reminder,
    bool clearSessionStart = false,
  }) =>
      SleepTrackerState(
        status: status ?? this.status,
        sessionStart: clearSessionStart ? null : (sessionStart ?? this.sessionStart),
        history: history ?? this.history,
        reminder: reminder ?? this.reminder,
      );

  Duration get currentDuration {
    if (sessionStart == null || status == SleepTrackingStatus.idle) return Duration.zero;
    return DateTime.now().difference(sessionStart!);
  }

  SleepSession? get lastSession => history.isNotEmpty ? history.last : null;
}
