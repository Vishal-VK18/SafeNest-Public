import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';

class AppointmentModel {
  final String id;
  final String title;
  final String doctorName;
  final String? doctorSpecialty;
  final String location;
  final String department;
  final String contactNumber;
  final DateTime date;
  final String? time;
  final String? notes;
  final String type;
  final String status;
  final bool calendarAdded;
  final List<String>? preparationChecklist;
  final Map<String, bool>? checklist; // Real-time sync for checklist items
  
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
    this.doctorSpecialty,
    this.department = '',
    this.contactNumber = '',
    this.time,
    this.notes,
    this.type = 'Routine Check-up',
    this.status = 'upcoming',
    this.calendarAdded = false,
    this.preparationChecklist,
    this.checklist,
    this.has24hReminderSent = false,
    this.has2hReminderSent = false,
    this.isCompleted = false,
    this.isMissed = false,
    this.reportFilePath,
    this.reportFileName,
    this.reportUploadDate,
  });

  Map<String, dynamic> toFirebaseMap() {
    return {
      'id': id,
      'doctor_name': doctorName,
      'doctor_specialty': doctorSpecialty ?? '',
      'date': date.toIso8601String(),
      'time': time ?? '',
      'location': location,
      'notes': notes ?? '',
      'type': type,
      'status': isCompleted ? 'completed' : (isMissed ? 'missed' : status),
      'calendar_added': calendarAdded,
      'preparation_checklist': preparationChecklist ?? [],
      'checklist': checklist ?? {},
      'created_at': DateTime.now().toIso8601String(),
      'last_updated': ServerValue.timestamp,
    };
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Checkup',
      doctorName: json['doctorName'] as String? ?? json['doctor_name'] as String? ?? '',
      doctorSpecialty: json['doctorSpecialty'] as String? ?? json['doctor_specialty'] as String?,
      location: json['location'] as String? ?? '',
      department: json['department'] as String? ?? '',
      contactNumber: json['contactNumber'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : DateTime.now(),
      time: json['time'] as String?,
      notes: json['notes'] as String?,
      type: json['type'] as String? ?? 'Routine Check-up',
      status: json['status'] as String? ?? 'upcoming',
      calendarAdded: json['calendar_added'] as bool? ?? json['calendarAdded'] as bool? ?? false,
      preparationChecklist: json['preparation_checklist'] != null 
          ? List<String>.from(json['preparation_checklist']) 
          : null,
      checklist: json['checklist'] != null 
          ? Map<String, bool>.from(json['checklist']) 
          : null,
      has24hReminderSent: json['has24hReminderSent'] as bool? ?? false,
      has2hReminderSent: json['has2hReminderSent'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? (json['status'] == 'completed'),
      isMissed: json['isMissed'] as bool? ?? (json['status'] == 'missed'),
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
        'doctorSpecialty': doctorSpecialty,
        'location': location,
        'department': department,
        'contactNumber': contactNumber,
        'date': date.toIso8601String(),
        'time': time,
        'notes': notes,
        'type': type,
        'status': status,
        'calendarAdded': calendarAdded,
        'preparationChecklist': preparationChecklist,
        'checklist': checklist,
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
    String? doctorSpecialty,
    String? location,
    String? department,
    String? contactNumber,
    DateTime? date,
    String? time,
    String? notes,
    String? type,
    String? status,
    bool? calendarAdded,
    List<String>? preparationChecklist,
    Map<String, bool>? checklist,
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
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      location: location ?? this.location,
      department: department ?? this.department,
      contactNumber: contactNumber ?? this.contactNumber,
      date: date ?? this.date,
      time: time ?? this.time,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      status: status ?? this.status,
      calendarAdded: calendarAdded ?? this.calendarAdded,
      preparationChecklist: preparationChecklist ?? this.preparationChecklist,
      checklist: checklist ?? this.checklist,
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
