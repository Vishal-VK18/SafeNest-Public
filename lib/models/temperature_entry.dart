// lib/models/temperature_entry.dart
//
// Lightweight model for a single temperature log entry.
// Shared between temperature_page.dart, temperature_log_page.dart,
// and the temperatureLogProvider.

class TemperatureEntry {
  final double value;
  final DateTime timestamp;

  const TemperatureEntry({required this.value, required this.timestamp});
}
