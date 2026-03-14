import 'package:flutter/material.dart';

enum LogParameter {
  heartRate,
  temperature,
  spo2,
  hydration,
  sleep,
  fallDetection,
}

extension LogParameterExtension on LogParameter {

  String get displayName {
    switch (this) {
      case LogParameter.heartRate:     return 'Heart Rate';
      case LogParameter.temperature:   return 'Body Temperature';
      case LogParameter.spo2:         return 'Oxygen Level';
      case LogParameter.hydration:    return 'Hydration';
      case LogParameter.sleep:        return 'Sleep Duration';
      case LogParameter.fallDetection: return 'Fall Detection';
    }
  }

  String get unit {
    switch (this) {
      case LogParameter.heartRate:     return 'BPM';
      case LogParameter.temperature:   return '°C';
      case LogParameter.spo2:         return '%';
      case LogParameter.hydration:    return 'cups';
      case LogParameter.sleep:        return 'min';
      case LogParameter.fallDetection: return 'events';
    }
  }

  String get firebaseKey {
    switch (this) {
      case LogParameter.heartRate:     return 'heart_rate';
      case LogParameter.temperature:   return 'temperature';
      case LogParameter.spo2:         return 'spo2';
      case LogParameter.hydration:    return 'total_intake';
      case LogParameter.sleep:        return 'duration_minutes';
      case LogParameter.fallDetection: return 'fall_detected';
    }
  }

  String get firebasePath {
    switch (this) {
      case LogParameter.heartRate:
      case LogParameter.temperature:
      case LogParameter.spo2:
        return 'vitals';
      case LogParameter.hydration:
        return 'hydration';
      case LogParameter.sleep:
        return 'sleep';
      case LogParameter.fallDetection:
        return 'activity_log';
    }
  }

  String get iconAsset {
    switch (this) {
      case LogParameter.heartRate:     return '❤️';
      case LogParameter.temperature:   return '🌡️';
      case LogParameter.spo2:         return '💧';
      case LogParameter.hydration:    return '🥤';
      case LogParameter.sleep:        return '🌙';
      case LogParameter.fallDetection: return '🛡️';
    }
  }

  Color get accentColor {
    switch (this) {
      case LogParameter.heartRate:     return const Color(0xFFE9A48E);
      case LogParameter.temperature:   return const Color(0xFFE68C6C);
      case LogParameter.spo2:         return const Color(0xFFD4957E);
      case LogParameter.hydration:    return const Color(0xFFE9A48E);
      case LogParameter.sleep:        return const Color(0xFFC4806A);
      case LogParameter.fallDetection: return const Color(0xFFCC8877);
    }
  }
}
