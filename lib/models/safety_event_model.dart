// lib/models/safety_event_model.dart

enum SafetyEventType { fall, sos, system, vitals }

enum SafetyEventStatus { resolved, pending, info }

class SafetyEventModel {
  final String id;
  final SafetyEventType type;
  final DateTime timestamp;
  final String description;
  final String? location;
  final SafetyEventStatus status;

  SafetyEventModel({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.description,
    this.location,
    this.status = SafetyEventStatus.info,
  });

  factory SafetyEventModel.fromJson(Map<String, dynamic> json) => SafetyEventModel(
        id:          json['id'] as String,
        type:        SafetyEventType.values.firstWhere((e) => e.name == json['type']),
        timestamp:   DateTime.parse(json['timestamp'] as String),
        description: json['description'] as String,
        location:    json['location'] as String?,
        status:      SafetyEventStatus.values.firstWhere((e) => e.name == json['status']),
      );

  Map<String, dynamic> toJson() => {
        'id':          id,
        'type':        type.name,
        'timestamp':   timestamp.toIso8601String(),
        'description': description,
        'location':    location,
        'status':      status.name,
      };
}
