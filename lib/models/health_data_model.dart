// lib/models/health_data_model.dart
import 'dart:convert';
import '../utils/constants.dart';

class HealthDataModel {
  final int heartRate;
  final double temperature;
  final bool fallDetected;
  final int pregnancyWeek;
  final int watchBattery;
  final int simBattery;
  final int simSignal;       // 0–4
  final String networkType;  // "2G" | "3G" | "4G" | "LTE-M"
  final double gpsLat;
  final double gpsLng;
  final DateTime? lastSmsTime;
  final DateTime receivedAt;

  const HealthDataModel({
    required this.heartRate,
    required this.temperature,
    required this.fallDetected,
    required this.pregnancyWeek,
    required this.watchBattery,
    required this.simBattery,
    required this.simSignal,
    required this.networkType,
    required this.gpsLat,
    required this.gpsLng,
    this.lastSmsTime,
    required this.receivedAt,
  });

  // ─── JSON parsing (safe, null-aware) ────────────────────────────────────────
  factory HealthDataModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedSmsTime;
    try {
      final raw = json['last_sms_time'];
      if (raw != null && raw.toString().isNotEmpty) {
        parsedSmsTime = DateTime.parse(raw.toString());
      }
    } catch (_) {}

    return HealthDataModel(
      heartRate:     (json['heart_rate']     as num?)?.toInt()    ?? 0,
      temperature:   (json['temperature']    as num?)?.toDouble() ?? 0.0,
      fallDetected:  (json['fall_detected']  as bool?)            ?? false,
      pregnancyWeek: (json['pregnancy_week'] as num?)?.toInt()    ?? 0,
      watchBattery:  (json['watch_battery']  as num?)?.toInt()    ?? 0,
      simBattery:    (json['sim_battery']    as num?)?.toInt()    ?? 0,
      simSignal:     (json['sim_signal']     as num?)?.toInt()    ?? 0,
      networkType:   (json['network_type']   as String?)          ?? 'N/A',
      gpsLat:        (json['gps_lat']        as num?)?.toDouble() ?? 0.0,
      gpsLng:        (json['gps_lng']        as num?)?.toDouble() ?? 0.0,
      lastSmsTime:   parsedSmsTime,
      receivedAt:    DateTime.now(),
    );
  }

  factory HealthDataModel.fromJsonString(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return HealthDataModel.fromJson(map);
    } catch (e) {
      return HealthDataModel.empty();
    }
  }

  Map<String, dynamic> toJson() => {
    'heart_rate':     heartRate,
    'temperature':    temperature,
    'fall_detected':  fallDetected,
    'pregnancy_week': pregnancyWeek,
    'watch_battery':  watchBattery,
    'sim_battery':    simBattery,
    'sim_signal':     simSignal,
    'network_type':   networkType,
    'gps_lat':        gpsLat,
    'gps_lng':        gpsLng,
    'last_sms_time':  lastSmsTime?.toIso8601String(),
  };

  String toJsonString() => jsonEncode(toJson());

  // ─── Default / empty ────────────────────────────────────────────────────────
  factory HealthDataModel.empty() => HealthDataModel(
    heartRate:     0,
    temperature:   0.0,
    fallDetected:  false,
    pregnancyWeek: 22,
    watchBattery:  100,
    simBattery:    100,
    simSignal:     4,
    networkType:   '4G',
    gpsLat:        0.0,
    gpsLng:        0.0,
    receivedAt:    DateTime.now(),
  );

  // ─── Demo / mock ────────────────────────────────────────────────────────────
  factory HealthDataModel.mock() => HealthDataModel(
    heartRate:     82,
    temperature:   36.7,
    fallDetected:  false,
    pregnancyWeek: 22,
    watchBattery:  85,
    simBattery:    72,
    simSignal:     4,
    networkType:   '4G',
    gpsLat:        12.9716,
    gpsLng:        77.5946,
    lastSmsTime:   DateTime(2026, 2, 22, 18, 30),
    receivedAt:    DateTime.now(),
  );

  // ─── Status helpers ──────────────────────────────────────────────────────────
  bool get isHeartRateNormal =>
      heartRate >= AppConstants.heartRateMin &&
      heartRate <= AppConstants.heartRateMax;

  bool get isTemperatureNormal =>
      temperature < AppConstants.tempHighThreshold &&
      temperature >= AppConstants.tempLowThreshold;

  String get heartRateStatus => isHeartRateNormal ? 'Normal' : 'Abnormal';
  String get temperatureStatus => isTemperatureNormal ? 'Normal' : 'High';
  String get fallStatus => fallDetected ? 'FALL DETECTED' : 'No Issues';

  String get gpsString =>
      gpsLat == 0.0 && gpsLng == 0.0
          ? 'Unavailable'
          : '${gpsLat.toStringAsFixed(4)}, ${gpsLng.toStringAsFixed(4)}';

  String get signalLabel {
    switch (simSignal) {
      case 4: return 'Excellent';
      case 3: return 'Good';
      case 2: return 'Fair';
      case 1: return 'Poor';
      default: return 'No Signal';
    }
  }

  HealthDataModel copyWith({
    int? heartRate,
    double? temperature,
    bool? fallDetected,
    int? pregnancyWeek,
    int? watchBattery,
    int? simBattery,
    int? simSignal,
    String? networkType,
    double? gpsLat,
    double? gpsLng,
    DateTime? lastSmsTime,
    DateTime? receivedAt,
  }) => HealthDataModel(
    heartRate:     heartRate     ?? this.heartRate,
    temperature:   temperature   ?? this.temperature,
    fallDetected:  fallDetected  ?? this.fallDetected,
    pregnancyWeek: pregnancyWeek ?? this.pregnancyWeek,
    watchBattery:  watchBattery  ?? this.watchBattery,
    simBattery:    simBattery    ?? this.simBattery,
    simSignal:     simSignal     ?? this.simSignal,
    networkType:   networkType   ?? this.networkType,
    gpsLat:        gpsLat        ?? this.gpsLat,
    gpsLng:        gpsLng        ?? this.gpsLng,
    lastSmsTime:   lastSmsTime   ?? this.lastSmsTime,
    receivedAt:    receivedAt    ?? this.receivedAt,
  );
}
