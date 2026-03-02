// lib/models/appointment_model.dart
import 'dart:convert';

class AppointmentModel {
  final String id;
  final String title;
  final String doctorName;
  final String location;
  final String department;
  final String contactNumber;
  final DateTime date;
  final bool has24hReminderSent;
  final bool has2hReminderSent;
  final bool isCompleted;
  final bool isMissed;
  final String? reportFilePath;
  final String? reportFileName;
  final DateTime? reportUploadDate;

  const AppointmentModel({
    required this.id,
    required this.title,
    required this.doctorName,
    required this.location,
    required this.date,
    this.department = '',
    this.contactNumber = '',
    this.has24hReminderSent = false,
    this.has2hReminderSent = false,
    this.isCompleted = false,
    this.isMissed = false,
    this.reportFilePath,
    this.reportFileName,
    this.reportUploadDate,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Checkup',
      doctorName: json['doctorName'] as String? ?? '',
      location: json['location'] as String? ?? '',
      department: json['department'] as String? ?? '',
      contactNumber: json['contactNumber'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : DateTime.now(),
      has24hReminderSent: json['has24hReminderSent'] as bool? ?? false,
      has2hReminderSent: json['has2hReminderSent'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isMissed: json['isMissed'] as bool? ?? false,
      reportFilePath: json['reportFilePath'] as String?,
      reportFileName: json['reportFileName'] as String?,
      reportUploadDate: json['reportUploadDate'] != null
          ? DateTime.tryParse(json['reportUploadDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'doctorName': doctorName,
        'location': location,
        'department': department,
        'contactNumber': contactNumber,
        'date': date.toIso8601String(),
        'has24hReminderSent': has24hReminderSent,
        'has2hReminderSent': has2hReminderSent,
        'isCompleted': isCompleted,
        'isMissed': isMissed,
        'reportFilePath': reportFilePath,
        'reportFileName': reportFileName,
        'reportUploadDate': reportUploadDate?.toIso8601String(),
      };

  AppointmentModel copyWith({
    String? id,
    String? title,
    String? doctorName,
    String? location,
    String? department,
    String? contactNumber,
    DateTime? date,
    bool? has24hReminderSent,
    bool? has2hReminderSent,
    bool? isCompleted,
    bool? isMissed,
    String? reportFilePath,
    String? reportFileName,
    DateTime? reportUploadDate,
    bool clearReport = false,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      doctorName: doctorName ?? this.doctorName,
      location: location ?? this.location,
      department: department ?? this.department,
      contactNumber: contactNumber ?? this.contactNumber,
      date: date ?? this.date,
      has24hReminderSent: has24hReminderSent ?? this.has24hReminderSent,
      has2hReminderSent: has2hReminderSent ?? this.has2hReminderSent,
      isCompleted: isCompleted ?? this.isCompleted,
      isMissed: isMissed ?? this.isMissed,
      reportFilePath: clearReport ? null : (reportFilePath ?? this.reportFilePath),
      reportFileName: clearReport ? null : (reportFileName ?? this.reportFileName),
      reportUploadDate:
          clearReport ? null : (reportUploadDate ?? this.reportUploadDate),
    );
  }

  static List<AppointmentModel> decodeList(String jsonStr) {
    try {
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String encodeList(List<AppointmentModel> list) {
    return jsonEncode(list.map((e) => e.toJson()).toList());
  }
}
