// lib/models/hydration_model.dart
import 'dart:convert';

// ─── Single logged water entry ─────────────────────────────────────────────────
class HydrationEntry {
  final DateTime timestamp;
  final double liters;

  const HydrationEntry({required this.timestamp, required this.liters});

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'liters': liters,
      };

  factory HydrationEntry.fromJson(Map<String, dynamic> json) => HydrationEntry(
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        liters: (json['liters'] as num?)?.toDouble() ?? 0.0,
      );
}

// ─── Time bucket enum ──────────────────────────────────────────────────────────
enum HydrationBucket { morning, afternoon, evening }

extension HydrationBucketX on DateTime {
  HydrationBucket get bucket {
    if (hour >= 5 && hour < 12) return HydrationBucket.morning;
    if (hour >= 12 && hour < 18) return HydrationBucket.afternoon;
    return HydrationBucket.evening;
  }
}

// ─── Main model ───────────────────────────────────────────────────────────────
class HydrationModel {
  final double intakeLiters;
  final DateTime lastUpdated;
  final int streakDays;
  final Map<String, double> history; // ISO Date String → Liters

  // New: time-bucketed entries for today (cleared on midnight reset)
  final List<HydrationEntry> todayEntries;

  // Reminder settings
  final bool reminderEnabled;
  final int reminderFreqHours; // 1 | 2 | 3 | 4

  const HydrationModel({
    required this.intakeLiters,
    required this.lastUpdated,
    required this.streakDays,
    required this.history,
    this.todayEntries = const [],
    this.reminderEnabled = false,
    this.reminderFreqHours = 2,
  });

  factory HydrationModel.empty() => HydrationModel(
        intakeLiters: 0.0,
        lastUpdated: DateTime.now(),
        streakDays: 0,
        history: {},
        todayEntries: [],
        reminderEnabled: false,
        reminderFreqHours: 2,
      );

  // ── Time-bucket helpers ────────────────────────────────────────────────────
  double get morningLiters => _bucketSum(HydrationBucket.morning);
  double get afternoonLiters => _bucketSum(HydrationBucket.afternoon);
  double get eveningLiters => _bucketSum(HydrationBucket.evening);

  double _bucketSum(HydrationBucket b) => todayEntries
      .where((e) => e.timestamp.bucket == b)
      .fold(0.0, (sum, e) => sum + e.liters);

  /// 7-day rolling average from history (including today)
  double get weeklyAverage {
    if (history.isEmpty && intakeLiters == 0) return 0.0;
    final values = <double>[intakeLiters, ...history.values.take(6)];
    return values.reduce((a, b) => a + b) / values.length;
  }

  // ── Serialisation ──────────────────────────────────────────────────────────
  factory HydrationModel.fromJson(Map<String, dynamic> json) => HydrationModel(
        intakeLiters: (json['intakeLiters'] as num?)?.toDouble() ?? 0.0,
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.tryParse(json['lastUpdated']) ?? DateTime.now()
            : DateTime.now(),
        streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
        history: (json['history'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            {},
        todayEntries: (json['todayEntries'] as List<dynamic>?)
                ?.map((e) =>
                    HydrationEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        reminderEnabled: (json['reminderEnabled'] as bool?) ?? false,
        reminderFreqHours: (json['reminderFreqHours'] as num?)?.toInt() ?? 2,
      );

  Map<String, dynamic> toJson() => {
        'intakeLiters': intakeLiters,
        'lastUpdated': lastUpdated.toIso8601String(),
        'streakDays': streakDays,
        'history': history,
        'todayEntries': todayEntries.map((e) => e.toJson()).toList(),
        'reminderEnabled': reminderEnabled,
        'reminderFreqHours': reminderFreqHours,
      };

  String toJsonString() => jsonEncode(toJson());

  factory HydrationModel.fromJsonString(String str) {
    try {
      return HydrationModel.fromJson(jsonDecode(str));
    } catch (_) {
      return HydrationModel.empty();
    }
  }

  HydrationModel copyWith({
    double? intakeLiters,
    DateTime? lastUpdated,
    int? streakDays,
    Map<String, double>? history,
    List<HydrationEntry>? todayEntries,
    bool? reminderEnabled,
    int? reminderFreqHours,
  }) =>
      HydrationModel(
        intakeLiters: intakeLiters ?? this.intakeLiters,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        streakDays: streakDays ?? this.streakDays,
        history: history ?? this.history,
        todayEntries: todayEntries ?? this.todayEntries,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderFreqHours: reminderFreqHours ?? this.reminderFreqHours,
      );
}
