// lib/models/sleep_oxygen_model.dart
import 'dart:convert';

class SleepOxygenModel {
  final double sleepDurationHours;
  final double deepSleepPercentage;
  final int interruptions;
  final double averageSpO2;
  final DateTime lastUpdated;
  final List<double> spO2History;

  const SleepOxygenModel({
    required this.sleepDurationHours,
    required this.deepSleepPercentage,
    required this.interruptions,
    required this.averageSpO2,
    required this.lastUpdated,
    required this.spO2History,
  });

  factory SleepOxygenModel.empty() => SleepOxygenModel(
    sleepDurationHours: 0.0,
    deepSleepPercentage: 0.0,
    interruptions: 0,
    averageSpO2: 98.0,
    lastUpdated: DateTime.now(),
    spO2History: [],
  );

  factory SleepOxygenModel.fromJson(Map<String, dynamic> json) {
    return SleepOxygenModel(
      sleepDurationHours: (json['sleepDurationHours'] as num?)?.toDouble() ?? 0.0,
      deepSleepPercentage: (json['deepSleepPercentage'] as num?)?.toDouble() ?? 0.0,
      interruptions: (json['interruptions'] as num?)?.toInt() ?? 0,
      averageSpO2: (json['averageSpO2'] as num?)?.toDouble() ?? 98.0,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.tryParse(json['lastUpdated']) ?? DateTime.now() 
          : DateTime.now(),
      spO2History: (json['spO2History'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'sleepDurationHours': sleepDurationHours,
    'deepSleepPercentage': deepSleepPercentage,
    'interruptions': interruptions,
    'averageSpO2': averageSpO2,
    'lastUpdated': lastUpdated.toIso8601String(),
    'spO2History': spO2History,
  };

  String toJsonString() => jsonEncode(toJson());

  factory SleepOxygenModel.fromJsonString(String str) {
    try {
      return SleepOxygenModel.fromJson(jsonDecode(str));
    } catch (_) {
      return SleepOxygenModel.empty();
    }
  }

  SleepOxygenModel copyWith({
    double? sleepDurationHours,
    double? deepSleepPercentage,
    int? interruptions,
    double? averageSpO2,
    DateTime? lastUpdated,
    List<double>? spO2History,
  }) {
    return SleepOxygenModel(
      sleepDurationHours: sleepDurationHours ?? this.sleepDurationHours,
      deepSleepPercentage: deepSleepPercentage ?? this.deepSleepPercentage,
      interruptions: interruptions ?? this.interruptions,
      averageSpO2: averageSpO2 ?? this.averageSpO2,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      spO2History: spO2History ?? this.spO2History,
    );
  }
}
