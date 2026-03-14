import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/log_entry.dart';
import '../models/log_parameter.dart';

class FirebaseDatabaseService {

  static const String _databaseUrl =
    'https://safenest-5bbc2-default-rtdb.asia-southeast1.firebasedatabase.app';

  final String uid;
  late final DatabaseReference _db;

  FirebaseDatabaseService({required this.uid}) {
    // MUST use instanceFor with databaseURL for non-default regions
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _databaseUrl,
    ).ref('users/$uid');
  }

  // ══════════════════════════════════════════════════════════
  // ACTIVITY LOG — developer visibility in Firebase Console
  // ══════════════════════════════════════════════════════════

  Future<void> logActivity(
      String action, Map<String, dynamic> meta) async {
    if (uid.isEmpty) return;
    try {
      await _db.child('activity_log').push().set({
        'action': action,
        'meta': meta,
        'timestamp': ServerValue.timestamp,
        'platform': Platform.operatingSystem,
        'app_version': '1.0.0',
      });
    } catch (e) {
      debugPrint('[SafeNest DB] logActivity error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════
  // SESSION TRACKING
  // ══════════════════════════════════════════════════════════

  Future<void> logSessionStart() async {
    await logActivity('session_start', {
      'time': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
    });
  }

  Future<void> logSessionEnd() async {
    await logActivity('session_end', {
      'time': DateTime.now().toIso8601String(),
    });
  }

  // ══════════════════════════════════════════════════════════
  // USER PROFILE
  // Path: users/{uid}/profile/
  // ══════════════════════════════════════════════════════════

  Future<void> saveUserProfile(Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    try {
      await _db.child('profile').update({
        ...data,
        'last_updated': ServerValue.timestamp,
      });
      await logActivity('profile_updated', data);
    } catch (e) {
      debugPrint('[SafeNest DB] saveUserProfile error: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (uid.isEmpty) return null;
    try {
      final snap = await _db.child('profile').get();
      if (snap.exists && snap.value != null) {
        return Map<String, dynamic>.from(snap.value as Map);
      }
    } catch (e) {
      debugPrint('[SafeNest DB] getUserProfile error: $e');
    }
    return null;
  }

  Stream<DatabaseEvent> watchUserProfile() =>
      _db.child('profile').onValue;

  // ══════════════════════════════════════════════════════════
  // HYDRATION
  // Path: users/{uid}/hydration/{yyyy-MM-dd}/
  // ══════════════════════════════════════════════════════════

  Future<void> saveHydrationLog(
      String date, Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    try {
      await _db.child('hydration/$date').update({
        ...data,
        'last_updated': ServerValue.timestamp,
      });
      await logActivity('hydration_updated', {'date': date, ...data});
    } catch (e) {
      debugPrint('[SafeNest DB] saveHydrationLog error: $e');
    }
  }

  Future<Map<String, dynamic>?> getHydrationLogs() async {
    if (uid.isEmpty) return null;
    try {
      final snap = await _db.child('hydration').get();
      if (snap.exists && snap.value != null) {
        return Map<String, dynamic>.from(snap.value as Map);
      }
    } catch (e) {
      debugPrint('[SafeNest DB] getHydrationLogs error: $e');
    }
    return null;
  }

  Stream<DatabaseEvent> watchHydrationLogs() =>
      _db.child('hydration').onValue;

  // ══════════════════════════════════════════════════════════
  // SLEEP & OXYGEN
  // Path: users/{uid}/sleep/{yyyy-MM-dd}/
  // ══════════════════════════════════════════════════════════

  Future<void> saveSleepLog(
      String date, Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    try {
      await _db.child('sleep/$date').update({
        ...data,
        'last_updated': ServerValue.timestamp,
      });
      await logActivity('sleep_logged', {'date': date, ...data});
    } catch (e) {
      debugPrint('[SafeNest DB] saveSleepLog error: $e');
    }
  }

  Future<Map<String, dynamic>?> getSleepLogs() async {
    if (uid.isEmpty) return null;
    try {
      final snap = await _db.child('sleep').get();
      if (snap.exists && snap.value != null) {
        return Map<String, dynamic>.from(snap.value as Map);
      }
    } catch (e) {
      debugPrint('[SafeNest DB] getSleepLogs error: $e');
    }
    return null;
  }

  Stream<DatabaseEvent> watchSleepLogs() =>
      _db.child('sleep').onValue;

  // ══════════════════════════════════════════════════════════
  // APPOINTMENTS
  // Path: users/{uid}/appointments/{id}/
  // ══════════════════════════════════════════════════════════

  Future<void> saveAppointment(
      String id, Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    try {
      await _db.child('appointments/$id').update({
        ...data,
        'last_updated': ServerValue.timestamp,
      });
      await logActivity('appointment_saved', {'id': id, ...data});
    } catch (e) {
      debugPrint('[SafeNest DB] saveAppointment error: $e');
    }
  }

  Future<void> saveAppointmentWithCalendarFlag(
      String id,
      Map<String, dynamic> data,
      bool calendarAdded) async {
    if (uid.isEmpty) return;
    try {
      await _db.child('appointments/$id').update({
        ...data,
        'calendar_added': calendarAdded,
        'calendar_added_at': calendarAdded
            ? DateTime.now().toIso8601String()
            : null,
        'last_updated': ServerValue.timestamp,
      });

      debugPrint('[SafeNest DB] ✅ Appointment synced to Firebase: $id');

      await logActivity('appointment_calendar_synced', {
        'appointment_id': id,
        'doctor': data['doctor_name'] ?? data['doctorName'] ?? '',
        'type': data['type'] ?? '',
        'date': data['date'] ?? '',
        'calendar_added': calendarAdded,
      });

    } catch (e) {
      debugPrint('[SafeNest DB] ❌ Appointment Firebase sync error: $e');
    }
  }

  /// Fetch single appointment by ID
  Future<Map<String, dynamic>?> getAppointmentById(String id) async {
    if (uid.isEmpty) return null;
    try {
      final snap = await _db.child('appointments/$id').get();
      if (snap.exists && snap.value != null) {
        return Map<String, dynamic>.from(snap.value as Map);
      }
    } catch (e) {
      debugPrint('[SafeNest DB] getAppointmentById error: $e');
    }
    return null;
  }

  /// Update appointment checklist item status
  Future<void> updateChecklistItem(
      String appointmentId,
      String itemName,
      bool isChecked) async {
    if (uid.isEmpty) return;
    try {
      // Use child().set() for specific nested field
      final normalizedPath = itemName.replaceAll(' ', '-');
      await _db
          .child('appointments/$appointmentId/checklist/$normalizedPath')
          .set(isChecked);

      await logActivity('checklist_item_updated', {
        'appointment_id': appointmentId,
        'item': itemName,
        'checked': isChecked,
      });

      debugPrint('[SafeNest DB] ✅ Checklist updated: $itemName â†’ $isChecked');
    } catch (e) {
      debugPrint('[SafeNest DB] ❌ Checklist update error: $e');
    }
  }

  Future<void> deleteAppointment(String id) async {
    if (uid.isEmpty) return;
    try {
      await _db.child('appointments/$id').remove();
      await logActivity('appointment_deleted', {'id': id});
    } catch (e) {
      debugPrint('[SafeNest DB] deleteAppointment error: $e');
    }
  }

  Future<Map<String, dynamic>?> getAppointments() async {
    if (uid.isEmpty) return null;
    try {
      final snap = await _db.child('appointments').get();
      if (snap.exists && snap.value != null) {
        return Map<String, dynamic>.from(snap.value as Map);
      }
    } catch (e) {
      debugPrint('[SafeNest DB] getAppointments error: $e');
    }
    return null;
  }

  Stream<DatabaseEvent> watchAppointments() =>
      _db.child('appointments').onValue;

  // ══════════════════════════════════════════════════════════
  // EMERGENCY CONTACT
  // Path: users/{uid}/emergency_contact/
  // ══════════════════════════════════════════════════════════

  Future<void> saveEmergencyContact(Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    try {
      await _db.child('emergency_contact').update({
        ...data,
        'last_updated': ServerValue.timestamp,
      });
      await logActivity('emergency_contact_updated', data);
    } catch (e) {
      debugPrint('[SafeNest DB] saveEmergencyContact error: $e');
    }
  }

  Future<Map<String, dynamic>?> getEmergencyContact() async {
    if (uid.isEmpty) return null;
    try {
      final snap = await _db.child('emergency_contact').get();
      if (snap.exists && snap.value != null) {
        return Map<String, dynamic>.from(snap.value as Map);
      }
    } catch (e) {
      debugPrint('[SafeNest DB] getEmergencyContact error: $e');
    }
    return null;
  }

  Stream<DatabaseEvent> watchEmergencyContact() =>
      _db.child('emergency_contact').onValue;

  // ══════════════════════════════════════════════════════════
  // PREGNANCY JOURNEY
  // Path: users/{uid}/pregnancy/
  // ══════════════════════════════════════════════════════════

  Future<void> savePregnancyData(Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    try {
      await _db.child('pregnancy').update({
        ...data,
        'last_updated': ServerValue.timestamp,
      });
      await logActivity('pregnancy_data_updated', data);
    } catch (e) {
      debugPrint('[SafeNest DB] savePregnancyData error: $e');
    }
  }

  Future<Map<String, dynamic>?> getPregnancyData() async {
    if (uid.isEmpty) return null;
    try {
      final snap = await _db.child('pregnancy').get();
      if (snap.exists && snap.value != null) {
        return Map<String, dynamic>.from(snap.value as Map);
      }
    } catch (e) {
      debugPrint('[SafeNest DB] getPregnancyData error: $e');
    }
    return null;
  }

  Stream<DatabaseEvent> watchPregnancyData() =>
      _db.child('pregnancy').onValue;

  // ══════════════════════════════════════════════════════════
  // VITALS
  // Path: users/{uid}/vitals/{yyyy-MM-dd}/
  // ══════════════════════════════════════════════════════════

  Future<void> saveVitalsLog(
      String date, Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    try {
      await _db.child('vitals/$date').update({
        ...data,
        'last_updated': ServerValue.timestamp,
      });
      await logActivity('vitals_logged', {'date': date, ...data});
    } catch (e) {
      debugPrint('[SafeNest DB] saveVitalsLog error: $e');
    }
  }

  Future<Map<String, dynamic>?> getVitalsLogs() async {
    if (uid.isEmpty) return null;
    try {
      final snap = await _db.child('vitals').get();
      if (snap.exists && snap.value != null) {
        return Map<String, dynamic>.from(snap.value as Map);
      }
    } catch (e) {
      debugPrint('[SafeNest DB] getVitalsLogs error: $e');
    }
    return null;
  }

  Stream<DatabaseEvent> watchVitals() =>
      _db.child('vitals').onValue;

  // ══════════════════════════════════════════════════════════
  // SETTINGS
  // Path: users/{uid}/settings/
  // ══════════════════════════════════════════════════════════

  Future<void> saveSettings(Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    try {
      await _db.child('settings').update({
        ...data,
        'last_updated': ServerValue.timestamp,
      });
      await logActivity('settings_updated', data);
    } catch (e) {
      debugPrint('[SafeNest DB] saveSettings error: $e');
    }
  }

  Future<Map<String, dynamic>?> getSettings() async {
    if (uid.isEmpty) return null;
    try {
      final snap = await _db.child('settings').get();
      if (snap.exists && snap.value != null) {
        return Map<String, dynamic>.from(snap.value as Map);
      }
    } catch (e) {
      debugPrint('[SafeNest DB] getSettings error: $e');
    }
    return null;
  }

  Stream<DatabaseEvent> watchSettings() =>
      _db.child('settings').onValue;

  // ══════════════════════════════════════════════════════════
  // ALERTS
  // Path: users/{uid}/alerts/
  // ══════════════════════════════════════════════════════════

  Future<void> saveAlert(Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    try {
      await _db.child('alerts').push().set({
        ...data,
        'read': false,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('[SafeNest DB] saveAlert error: $e');
    }
  }

  Future<void> markAlertRead(String alertId) async {
    if (uid.isEmpty) return;
    try {
      await _db.child('alerts/$alertId').update({'read': true});
    } catch (e) {
      debugPrint('[SafeNest DB] markAlertRead error: $e');
    }
  }

  Stream<DatabaseEvent> watchAlerts() =>
      _db.child('alerts').onValue;

  // ══════════════════════════════════════════════════════════
  // LOGS VIEWER — fetch historical data per parameter
  // ══════════════════════════════════════════════════════════

  /// Fetch all vitals logs (heart rate, temperature, spo2)
  /// Returns map of date → vitals map
  Future<Map<String, dynamic>?> fetchVitalsHistory() async {
    try {
      final snap = await _db.child('vitals').get();
      if (snap.exists && snap.value != null) {
        return Map<String, dynamic>.from(snap.value as Map);
      }
    } catch (e) {
      debugPrint('[SafeNest DB] fetchVitalsHistory error: $e');
    }
    return null;
  }

  /// Fetch all hydration logs
  /// Returns map of date → hydration map
  Future<Map<String, dynamic>?> fetchHydrationHistory() async {
    try {
      final snap = await _db.child('hydration').get();
      if (snap.exists && snap.value != null) {
        return Map<String, dynamic>.from(snap.value as Map);
      }
    } catch (e) {
      debugPrint('[SafeNest DB] fetchHydrationHistory error: $e');
    }
    return null;
  }

  /// Fetch all sleep logs
  Future<Map<String, dynamic>?> fetchSleepHistory() async {
    try {
      final snap = await _db.child('sleep').get();
      if (snap.exists && snap.value != null) {
        return Map<String, dynamic>.from(snap.value as Map);
      }
    } catch (e) {
      debugPrint('[SafeNest DB] fetchSleepHistory error: $e');
    }
    return null;
  }

  /// Fetch fall detection events from activity_log
  /// Filters entries where action == 'fall_detected'
  Future<List<Map<String, dynamic>>> fetchFallDetectionHistory() async {
    try {
      final snap = await _db.child('activity_log').get();
      if (snap.exists && snap.value != null) {
        final allLogs = Map<String, dynamic>.from(snap.value as Map);
        final fallEvents = <Map<String, dynamic>>[];
        allLogs.forEach((key, value) {
          final entry = Map<String, dynamic>.from(value as Map);
          if (entry['action'] == 'fall_detected') {
            fallEvents.add({...entry, 'id': key});
          }
        });
        // Sort by timestamp descending (newest first)
        fallEvents.sort((a, b) =>
          (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
        return fallEvents;
      }
    } catch (e) {
      debugPrint('[SafeNest DB] fetchFallDetectionHistory error: $e');
    }
    return [];
  }

  /// Generic method to fetch logs for any parameter
  /// between a start and end date range
  Future<List<LogEntry>> fetchLogsForParameter({
    required LogParameter parameter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final List<LogEntry> entries = [];

    try {
      Map<String, dynamic>? raw;

      if (parameter == LogParameter.fallDetection) {
        final falls = await fetchFallDetectionHistory();
        return falls.map((f) => LogEntry(
          date: f['meta']?['date'] ?? '',
          timestamp: f['timestamp']?.toString() ?? '',
          parameterName: 'fall_detected',
          value: 1,
          unit: 'event',
          note: f['meta']?['location'],
        )).toList();
      }

      switch (parameter) {
        case LogParameter.heartRate:
        case LogParameter.temperature:
        case LogParameter.spo2:
          raw = await fetchVitalsHistory();
          break;
        case LogParameter.hydration:
          raw = await fetchHydrationHistory();
          break;
        case LogParameter.sleep:
          raw = await fetchSleepHistory();
          break;
        default:
          break;
      }

      if (raw == null) return [];

      raw.forEach((date, value) {
        try {
          final dateObj = DateTime.parse(date);

          // Apply date range filter if provided
          if (startDate != null && dateObj.isBefore(startDate)) return;
          if (endDate != null && dateObj.isAfter(endDate)) return;

          final dayData = Map<String, dynamic>.from(value as Map);
          final rawValue = dayData[parameter.firebaseKey];

          if (rawValue != null) {
            entries.add(LogEntry(
              date: date,
              timestamp: dayData['recorded_at']?.toString() ?? date,
              parameterName: parameter.firebaseKey,
              value: rawValue,
              unit: parameter.unit,
              note: dayData['note'],
            ));
          }
        } catch (e) {
          debugPrint('[SafeNest DB] fetchLogsForParameter parse error: $e');
        }
      });

      // Sort newest first
      entries.sort((a, b) => b.date.compareTo(a.date));

    } catch (e) {
      debugPrint('[SafeNest DB] fetchLogsForParameter error: $e');
    }

    return entries;
  }
}
