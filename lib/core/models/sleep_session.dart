import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class SleepSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final double? spo2Average;
  final String? quality;       // 'Poor', 'Fair', 'Good', 'Excellent'
  final String date;           // yyyy-MM-dd of the session

  const SleepSession({
    required this.id,
    required this.startTime,
    required this.date,
    this.endTime,
    this.durationMinutes,
    this.spo2Average,
    this.quality,
  });

  bool get isActive => endTime == null;

  String get formattedDuration {
    if (durationMinutes == null) return '0h 0m';
    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;
    return '${hours}h ${minutes}m';
  }

  String get qualityFromDuration {
    if (durationMinutes == null) return 'Unknown';
    if (durationMinutes! >= 480) return 'Excellent'; // 8+ hours
    if (durationMinutes! >= 360) return 'Good';      // 6-8 hours
    if (durationMinutes! >= 240) return 'Fair';      // 4-6 hours
    return 'Poor';                                    // under 4 hours
  }

  Map<String, dynamic> toFirebaseMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'spo2_average': spo2Average,
      'quality': quality ?? qualityFromDuration,
      'date': date,
      'is_active': isActive,
      'last_updated': ServerValue.timestamp,
    };
  }

  SleepSession copyWith({
    DateTime? endTime,
    int? durationMinutes,
    double? spo2Average,
    String? quality,
  }) {
    return SleepSession(
      id: id,
      startTime: startTime,
      date: date,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      spo2Average: spo2Average ?? this.spo2Average,
      quality: quality ?? this.quality,
    );
  }
}

class SleepReminderSettings {
  final bool enabled;
  final DateTime? reminderTime; // We'll store as DateTime for easier JSON but treat as TimeOfDay

  const SleepReminderSettings({
    this.enabled = false,
    this.reminderTime,
  });

  SleepReminderSettings copyWith({bool? enabled, DateTime? reminderTime}) {
    return SleepReminderSettings(
      enabled: enabled ?? this.enabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'reminder_time': reminderTime?.toIso8601String(),
      };

  factory SleepReminderSettings.fromJson(Map<String, dynamic> json) =>
      SleepReminderSettings(
        enabled: json['enabled'] as bool? ?? false,
        reminderTime: json['reminder_time'] != null
            ? DateTime.parse(json['reminder_time'] as String)
            : null,
      );
}

class SleepTrackerState {
  final SleepSession? activeSession;
  final SleepSession? lastSession;
  final List<SleepSession> history;
  final bool isTracking;
  final Duration elapsed;
  final bool isSaving;
  final String? error;
  final SleepReminderSettings reminder;

  const SleepTrackerState({
    this.activeSession,
    this.lastSession,
    this.history = const [],
    this.isTracking = false,
    this.elapsed = Duration.zero,
    this.isSaving = false,
    this.error,
    this.reminder = const SleepReminderSettings(),
  });

  SleepTrackerState copyWith({
    SleepSession? activeSession,
    SleepSession? lastSession,
    List<SleepSession>? history,
    bool? isTracking,
    Duration? elapsed,
    bool? isSaving,
    String? error,
    SleepReminderSettings? reminder,
  }) {
    return SleepTrackerState(
      activeSession: activeSession ?? this.activeSession,
      lastSession: lastSession ?? this.lastSession,
      history: history ?? this.history,
      isTracking: isTracking ?? this.isTracking,
      elapsed: elapsed ?? this.elapsed,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      reminder: reminder ?? this.reminder,
    );
  }
}
