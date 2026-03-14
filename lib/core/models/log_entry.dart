class LogEntry {
  final String date;           // yyyy-MM-dd
  final String timestamp;      // ISO string or Firebase timestamp
  final String parameterName;  // 'heart_rate', 'temperature', etc.
  final dynamic value;         // the actual reading value
  final String unit;           // 'BPM', '°C', '%', 'cups', 'min', etc.
  final String? note;          // optional note

  const LogEntry({
    required this.date,
    required this.timestamp,
    required this.parameterName,
    required this.value,
    required this.unit,
    this.note,
  });

  factory LogEntry.fromMap(String date, Map<String, dynamic> map,
      String parameterName, String unit) {
    return LogEntry(
      date: date,
      timestamp: map['recorded_at'] ?? 
                 map['last_updated']?.toString() ?? date,
      parameterName: parameterName,
      value: map[parameterName],
      unit: unit,
      note: map['note'],
    );
  }
}
