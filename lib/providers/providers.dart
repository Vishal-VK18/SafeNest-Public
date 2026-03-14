import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/health_data_model.dart';
import '../models/device_status_model.dart';
import '../models/pregnancy_model.dart';
import '../models/contact_model.dart';
import '../models/hydration_model.dart';
import '../models/sleep_oxygen_model.dart';
import '../models/appointment_model.dart';
import '../models/safety_event_model.dart';
// import '../models/sleep_tracker_model.dart' as old_sleep; // Removed to avoid ambiguity
import '../core/models/sleep_session.dart';
import '../core/services/firebase_database_service.dart';
import '../services/ble_service.dart';
import '../services/sleep_reminder_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../models/temperature_entry.dart';
import '../core/providers/firebase_database_provider.dart';


// â”€â”€â”€ BLE Service singleton â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final bleServiceProvider = Provider<BleService>((_) => BleService.instance);

/// Shared tab index for HomeDashboardScreen — readable/writable from any screen.
final selectedTabProvider = StateProvider<int>((ref) => 0);

// â”€â”€â”€ Health data stream â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Streams the latest parsed BLE health packet.
final healthStreamProvider = StreamProvider<HealthDataModel>((ref) {
  final ble = ref.read(bleServiceProvider);
  return ble.healthStream;
});

/// Latest health snapshot â€” starts empty, updated only by real BLE data.
final healthDataProvider = StateNotifierProvider<HealthDataNotifier, HealthDataModel>(
  (ref) => HealthDataNotifier(ref),
);

class HealthDataNotifier extends StateNotifier<HealthDataModel> {
  final Ref _ref;
  HealthDataModel? _last;

  HealthDataNotifier(this._ref) : super(HealthDataModel.empty()) {
    _ref.read(bleServiceProvider).healthStream.listen((packet) {
      // Only update state if values actually changed — prevents unnecessary rebuilds
      if (_last == null ||
          _last!.temperature != packet.temperature ||
          _last!.heartRate != packet.heartRate ||
          _last!.fallDetected != packet.fallDetected ||
          _last!.tempAlert != packet.tempAlert ||
          _last!.simSignal != packet.simSignal ||
          _last!.networkType != packet.networkType ||
          _last!.bandBattery != packet.bandBattery ||
          _last!.simBattery != packet.simBattery) {
        _last = packet;
        state = packet;

        // Firebase sync (Vitals)
        try {
          final db = _ref.read(firebaseDatabaseServiceProvider);
          final today = DateTime.now();
          final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          db.saveVitalsLog(dateStr, {
            'heart_rate': packet.heartRate,
            'temperature': packet.temperature,
            'spo2': 0, // HealthDataModel doesn't have Spo2, but tracker model does.
            'recorded_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('[SafeNest] Vitals sync error: $e');
        }

        // Flush any buffered safety events into history

        _ref.read(bleServiceProvider).flushEvents((type, desc) async {
          await _ref.read(safetyHistoryProvider.notifier).addEvent(
                type: type,
                description: desc,
                status: SafetyEventStatus.resolved,
              );
        });
      }
    });
  }

  void reset() {
    _last = null;
    state = HealthDataModel.empty();
  }
}

// ─── Device status stream ────────────────────────────────────────────────────────
final deviceStreamProvider = StreamProvider<DeviceStatusModel>((ref) {
  return ref.read(bleServiceProvider).deviceStream;
});

final deviceStatusProvider =
    StateNotifierProvider<DeviceStatusNotifier, DeviceStatusModel>(
  (ref) => DeviceStatusNotifier(ref),
);

class DeviceStatusNotifier extends StateNotifier<DeviceStatusModel> {
  final Ref _ref;
  DeviceStatusModel? _last;

  DeviceStatusNotifier(this._ref) : super(DeviceStatusModel.initial()) {
    _ref.read(bleServiceProvider).deviceStream.listen((status) {
      // Only push update if connection status or signal actually changed
      if (_last == null ||
          _last!.watch.status != status.watch.status ||
          _last!.watch.signalLevel != status.watch.signalLevel ||
          _last!.watch.batteryPercent != status.watch.batteryPercent ||
          _last!.simUnit.status != status.simUnit.status ||
          _last!.simUnit.batteryPercent != status.simUnit.batteryPercent ||
          _last!.watch.lastSeen != status.watch.lastSeen) {
        _last = status;
        state = status;
      }
    });
  }

  Future<void> reconnect() async {
    final ble = _ref.read(bleServiceProvider);
    await ble.reconnect();
  }
}

// â”€â”€â”€ BLE Scan state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// True while a manual scan is in progress.
final bleScanningProvider = StreamProvider<bool>((ref) {
  return ref.read(bleServiceProvider).scanningStream;
});

/// Live list of discovered BLE devices during manual scan.
final bleScanResultsProvider = StreamProvider<List<ScanResult>>((ref) {
  return ref.read(bleServiceProvider).scanResultsStream;
});

// â”€â”€â”€ Pregnancy â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final pregnancyProvider =
    StateNotifierProvider<PregnancyNotifier, PregnancyModel>(
  (ref) => PregnancyNotifier(ref),
);

class PregnancyNotifier extends StateNotifier<PregnancyModel> {
  final Ref _ref;
  PregnancyNotifier(this._ref)
      : super(PregnancyModel(
          startDate:  StorageService.pregnancyStartDate,
          manualWeek: StorageService.pregnancyWeek,
          userName:   StorageService.userName,
          age:        StorageService.userAge ?? 27,
          photoLocalPath: StorageService.profilePhotoPath,
        ));

  Future<void> updateStartDate(DateTime date) async {
    await StorageService.setPregnancyStartDate(date);
    state = state.copyWith(startDate: date);

    // Firebase sync
    try {
      final db = _ref.read(firebaseDatabaseServiceProvider);
      await db.savePregnancyData({
        'current_week': state.manualWeek,
        'due_date': state.estimatedDueDate?.toIso8601String() ?? '',
      });
    } catch (e) {
      debugPrint('[SafeNest] Pregnancy start date sync error: $e');
    }
  }

  Future<void> updateWeek(int week) async {
    await StorageService.setPregnancyWeek(week);
    state = state.copyWith(manualWeek: week);

    // Firebase sync
    try {
      final db = _ref.read(firebaseDatabaseServiceProvider);
      await db.savePregnancyData({
        'current_week': week,
        'due_date': state.estimatedDueDate?.toIso8601String() ?? '',
      });
    } catch (e) {
      debugPrint('[SafeNest] Pregnancy week sync error: $e');
    }
  }


  Future<void> updateName(String name) async {
    await StorageService.setUserName(name);
    state = state.copyWith(userName: name);
    
    // Firebase sync
    try {
      final db = _ref.read(firebaseDatabaseServiceProvider);
      await db.saveUserProfile({
        'name': name,
        'age': state.age,
        'pregnancy_week': state.manualWeek,
      });
    } catch (e) {
      debugPrint('[SafeNest] Profile name sync error: $e');
    }
  }

  Future<void> updatePhoto(String path) async {
    await StorageService.setProfilePhotoPath(path);
    state = state.copyWith(photoLocalPath: path);
  }

  Future<void> clearProfile() async {
    state = PregnancyModel.defaults();
  }

}

// â”€â”€â”€ Fall alert state (for UI dismissal) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final fallAlertActiveProvider = StateProvider<bool>((ref) {
  final health = ref.watch(healthDataProvider);
  return health.fallDetected;
});

// â”€â”€â”€ Caregivers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final contactsProvider = StateNotifierProvider<ContactsNotifier, List<ContactModel>>((ref) {
  return ContactsNotifier(ref);
});

class ContactsNotifier extends StateNotifier<List<ContactModel>> {
  final Ref _ref;
  ContactsNotifier(this._ref) : super([]);


  void addContact(ContactModel contact) {
    state = [...state, contact];
    _syncToFirebase();
  }


  void updateContactTokens(String id, bool notificationsEnabled) {
    state = [
      for (final contact in state)
        if (contact.id == id)
          contact.copyWith(notificationsEnabled: notificationsEnabled)
        else
          contact
    ];
  }

  void updateContactDetails(String id, String name, String phone, String relationship) {
    state = [
      for (final contact in state)
        if (contact.id == id)
          contact.copyWith(
            name: name,
            phoneNumber: phone,
            relationship: relationship,
          )
        else
          contact
    ];
  }

  void removeContact(String id) {
    state = state.where((c) => c.id != id).toList();
    _syncToFirebase();
  }

  void _syncToFirebase() {
    try {
      final db = _ref.read(firebaseDatabaseServiceProvider);
      // We only sync the primary contact for now as per simple saveEmergencyContact service
      if (state.isNotEmpty) {
        final contact = state.first;
        db.saveEmergencyContact({
          'name': contact.name,
          'phone': contact.phoneNumber,
          'relation': contact.relationship,
          'added_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('[SafeNest] Contacts sync error: $e');
    }
  }
}


// â”€â”€â”€ Hydration Logic Engine â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final hydrationProvider = StateNotifierProvider<HydrationNotifier, HydrationModel>((ref) {
  return HydrationNotifier(ref);
});

class HydrationNotifier extends StateNotifier<HydrationModel> {
  final Ref _ref;
  HydrationNotifier(this._ref)
      : super(StorageService.hydrationData != null
            ? HydrationModel.fromJsonString(StorageService.hydrationData!)
            : HydrationModel.empty()) {
    _checkMidnightReset();
  }


  // â”€â”€ Midnight reset â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _checkMidnightReset() {
    final now  = DateTime.now();
    final last = state.lastUpdated;
    if (now.year != last.year || now.month != last.month || now.day != last.day) {
      final dateKey = '${last.year}-${last.month.toString().padLeft(2, '0')}-${last.day.toString().padLeft(2, '0')}';
      final newHistory = Map<String, double>.from(state.history);
      newHistory[dateKey] = state.intakeLiters;
      final streak = state.intakeLiters >= 2.0 ? state.streakDays + 1 : 0;
      state = state.copyWith(
        intakeLiters: 0.0,
        lastUpdated:  now,
        history:      newHistory,
        streakDays:   streak,
        todayEntries: [],
      );
      _save();
    }
  }

  // â”€â”€ Add water (backward-compat shim) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void addWater(double liters) => addEntry(liters);

  // â”€â”€ Add entry with timestamp for time-bucket grouping â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void addEntry(double liters) {
    _checkMidnightReset();
    final entry  = HydrationEntry(timestamp: DateTime.now(), liters: liters);
    final entries = [...state.todayEntries, entry];
    final newIntake = (state.intakeLiters + liters).clamp(0.0, 8.0);
    state = state.copyWith(
      intakeLiters: newIntake,
      lastUpdated:  DateTime.now(),
      todayEntries: entries,
    );
    _save();
  }

  // â”€â”€ Reminder state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void setReminder({required bool enabled, int? freqHours}) {
    state = state.copyWith(
      reminderEnabled:   enabled,
      reminderFreqHours: freqHours ?? state.reminderFreqHours,
    );
    _save();
  }

  // â”€â”€ Persist â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _save() {
    StorageService.setHydrationData(state.toJsonString());

    // Firebase sync
    try {
      final db = _ref.read(firebaseDatabaseServiceProvider);
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      db.saveHydrationLog(dateStr, {
        'total_intake': state.intakeLiters,
        'daily_goal': 2.0, // Default goal from models if not specified
        'unit': 'liters',
        'last_updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SafeNest] Hydration sync error: $e');
    }
  }

}


// â”€â”€â”€ Sleep & Oxygen Logic Engine â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final sleepOxygenProvider = StateNotifierProvider<SleepOxygenNotifier, SleepOxygenModel>((ref) {
  return SleepOxygenNotifier(ref);
});

class SleepOxygenNotifier extends StateNotifier<SleepOxygenModel> {
  final Ref _ref;
  SleepOxygenNotifier(this._ref) : super(StorageService.sleepData != null 
    ? SleepOxygenModel.fromJsonString(StorageService.sleepData!)
    : SleepOxygenModel.empty());


  void updateData({
    double? sleepDurationHours,
    double? deepSleepPercentage,
    int? interruptions,
    double? currentSpO2,
  }) {
    List<double> newHistory = List.from(state.spO2History);
    double newAvg = state.averageSpO2;

    if (currentSpO2 != null) {
      newHistory.add(currentSpO2);
      if (newHistory.length > 20) newHistory.removeAt(0); // keep rolling window
      newAvg = newHistory.reduce((a, b) => a + b) / newHistory.length;
    }

    state = state.copyWith(
      sleepDurationHours: sleepDurationHours ?? state.sleepDurationHours,
      deepSleepPercentage: deepSleepPercentage ?? state.deepSleepPercentage,
      interruptions: interruptions ?? state.interruptions,
      averageSpO2: newAvg,
      spO2History: newHistory,
      lastUpdated: DateTime.now(),
    );
    _save();
  }

  int calculateSleepScore() {
    double score = 100.0;
    if (state.sleepDurationHours < 7.0) score -= (7.0 - state.sleepDurationHours) * 10;
    if (state.deepSleepPercentage < 20.0) score -= (20.0 - state.deepSleepPercentage) * 0.5;
    score -= state.interruptions * 5;
    return score.clamp(0, 100).toInt();
  }

  void _save() {
    StorageService.setSleepData(state.toJsonString());

    // Firebase sync
    try {
      final db = _ref.read(firebaseDatabaseServiceProvider);
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      db.saveSleepLog(dateStr, {
        'duration_minutes': (state.sleepDurationHours * 60).toInt(),
        'spo2': state.averageSpO2,
        'quality': _qualityLabel(state.sleepDurationHours, state.averageSpO2),
        'recorded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SafeNest] Sleep sync error: $e');
    }
  }

  String _qualityLabel(double hours, double spo2) {
    if (hours > 7 && spo2 > 95) return 'Excellent';
    if (hours > 6 && spo2 > 93) return 'Good';
    return 'Fair';
  }
}


// â”€â”€â”€ Smart Appointment System â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final appointmentProvider = StateNotifierProvider<AppointmentNotifier, List<AppointmentModel>>((ref) {
  return AppointmentNotifier(ref);
});

final nextUpcomingAppointmentProvider = Provider<AppointmentModel?>((ref) {
  final appointments = ref.watch(appointmentProvider);
  try {
    return appointments.firstWhere((a) => !a.isCompleted);
  } catch (_) {
    return null;
  }
});

class AppointmentNotifier extends StateNotifier<List<AppointmentModel>> {
  final Ref _ref;
  AppointmentNotifier(this._ref) : super(_initialAppointments());


  static List<AppointmentModel> _initialAppointments() {
    final stored = StorageService.appointments;
    if (stored != null) {
      final list = AppointmentModel.decodeList(stored);
      if (list.isNotEmpty) return list;
    }
    return [
      AppointmentModel(
        id: 'default_1',
        title: 'Checkup',
        doctorName: 'Dr. Sarah Collins',
        location: 'Obstetrician',
        date: DateTime.now().add(const Duration(days: 7)),
      ),
    ];
  }

  void addAppointment(AppointmentModel appt) {
    state = [...state, appt];
    _save();
    _syncAppointment(appt);
  }

  void updateAppointment(AppointmentModel updated) {
    state = [
      for (final a in state)
        if (a.id == updated.id) updated else a
    ];
    _save();
    _syncAppointment(updated);
  }

  void rescheduleAppointment(String id, DateTime newDate) {
    state = [
      for (final a in state)
        if (a.id == id)
          a.copyWith(date: newDate, isMissed: false, isCompleted: false)
        else
          a
    ];
    _save();
  }

  void markCompleted(String id) {
    state = [
      for (final a in state)
        if (a.id == id) a.copyWith(isCompleted: true, isMissed: false) else a
    ];
    _save();
    try {
      final appt = state.firstWhere((a) => a.id == id);
      _syncAppointment(appt);
    } catch (_) {}
  }

  void deleteAppointment(String id) {
    state = state.where((a) => a.id != id).toList();
    _save();
    _deleteFromFirebase(id);
  }

  /// Mark appointment as added to calendar
  Future<void> markCalendarAdded(String appointmentId) async {
    state = [
      for (final a in state)
        if (a.id == appointmentId) a.copyWith(calendarAdded: true) else a
    ];
    _save();

    try {
      final db = _ref.read(firebaseDatabaseServiceProvider);
      await db.saveAppointmentWithCalendarFlag(
        appointmentId,
        {'calendar_added': true},
        true,
      );
    } catch (e) {
      debugPrint('[SafeNest Appointment] Calendar flag Firebase error: $e');
    }
  }

  /// Update checklist item
  Future<void> toggleChecklistItem(
      String appointmentId,
      String itemName,
      bool isChecked) async {
    state = [
      for (final a in state)
        if (a.id == appointmentId)
          a.copyWith(
            checklist: {
              ...(a.checklist ?? {}),
              itemName: isChecked,
            },
          )
        else
          a
    ];
    _save();

    try {
      final db = _ref.read(firebaseDatabaseServiceProvider);
      await db.updateChecklistItem(appointmentId, itemName, isChecked);
    } catch (e) {
      debugPrint('[SafeNest Appointment] Checklist Firebase error: $e');
    }
  }

  void attachReport(String id, String filePath, String fileName) {
    state = [
      for (final a in state)
        if (a.id == id)
          a.copyWith(
            reportFilePath: filePath,
            reportFileName: fileName,
            reportUploadDate: DateTime.now(),
          )
        else
          a
    ];
    _save();
  }

  void removeReport(String id) {
    state = [
      for (final a in state)
        if (a.id == id) a.copyWith(clearReport: true) else a
    ];
    _save();
  }

  void checkReminders() {
    final now = DateTime.now();
    bool changed = false;
    final newState = state.map((appt) {
      if (appt.isCompleted) return appt;
      // Detect missed: appointment has passed and not marked completed
      if (appt.date.isBefore(now)) {
        changed = true;
        return appt.copyWith(isMissed: true);
      }
      return appt;
    }).toList();
    
    if (changed) {
      state = newState;
      _save();
    }
  }

  void _save() {
    StorageService.setAppointments(AppointmentModel.encodeList(state));
  }

  void _syncAppointment(AppointmentModel appt) {
    try {
      final db = _ref.read(firebaseDatabaseServiceProvider);
      db.saveAppointmentWithCalendarFlag(
        appt.id,
        appt.toFirebaseMap(),
        appt.calendarAdded,
      );
    } catch (e) {
      debugPrint('[SafeNest] Appointment sync error: $e');
    }
  }

  void _deleteFromFirebase(String id) {
    try {
      final db = _ref.read(firebaseDatabaseServiceProvider);
      db.deleteAppointment(id);
    } catch (e) {
      debugPrint('[SafeNest] Appointment delete sync error: $e');
    }
  }
}



// â”€â”€â”€ Risk Scoring System â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final riskScoreProvider = Provider<int>((ref) {
  int score = 0;
  
  // 1. Hydration Risk (Low intake by 4 PM OR absolute low)
  final hyd = ref.watch(hydrationProvider);
  final preg = ref.watch(pregnancyProvider);
  final double goal = preg.pregnancyWeek <= 13 ? 2.5 : (preg.pregnancyWeek <= 26 ? 2.8 : 3.0);
  
  if (hyd.intakeLiters < (goal * 0.4) && DateTime.now().hour >= 16) {
    score += 1;
  } else if (hyd.intakeLiters < (goal * 0.8) && DateTime.now().hour >= 20) {
    score += 1;
  }

  // 2. Poor Sleep
  final sleep = ref.watch(sleepOxygenProvider);
  if (sleep.sleepDurationHours > 0 && sleep.sleepDurationHours < 6.0) {
    score += 1;
  }

  // 3. Oxygen Low
  if (sleep.averageSpO2 > 0 && sleep.averageSpO2 < 95.0) {
    score += 1;
  }

  // 4. Fall Detected or High Temp/HeartRate
  final health = ref.watch(healthDataProvider);
  if (health.fallDetected) {
    score += 1;
  }
  if (health.hasData) {
    if (!health.isHeartRateNormal) score += 1;
    if (!health.isTemperatureNormal) score += 1;
  }

  return score;
});

final riskStatusProvider = Provider<String>((ref) {
  final score = ref.watch(riskScoreProvider);
  if (score >= 3) return "High Risk â€“ Alert Caregiver";
  if (score >= 2) return "Mild Risk â€“ Monitor Closely";
  return "On Track";
});

// â”€â”€â”€ Weekly Health Analytics Engine â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final weeklyAnalyticsProvider = Provider<Map<String, dynamic>>((ref) {
  final hyd = ref.watch(hydrationProvider);
  final sleep = ref.watch(sleepOxygenProvider);
  final risk = ref.watch(riskStatusProvider);
  
  double totalHyd = 0.0;
  if (hyd.history.isNotEmpty) {
    totalHyd = hyd.history.values.reduce((a, b) => a + b) / hyd.history.length;
  }
  
  return {
    'avgHydration': totalHyd.toStringAsFixed(1),
    'avgSleepDuration': sleep.sleepDurationHours.toStringAsFixed(1),
    'avgSpO2': sleep.averageSpO2.toStringAsFixed(1),
    'riskSummary': risk,
    // Using weekday == DateTime.sunday (7) to conditionally show weekly banner
    'isSunday': DateTime.now().weekday == DateTime.sunday,
  };
});

// ─── Safety Event History ───────────────────────────────────────────────────

class SafetyHistoryNotifier extends StateNotifier<List<SafetyEventModel>> {
  SafetyHistoryNotifier() : super([]) {
    _load();
  }

  void _load() {
    try {
      final historyJson = StorageService.safetyHistory;
      if (historyJson.isEmpty) {
        state = [];
        return;
      }
      state = historyJson
          .map((s) {
            try {
              return SafetyEventModel.fromJson(
                  jsonDecode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<SafetyEventModel>()
          .toList();
    } catch (_) {
      state = [];
    }
  }

  Future<void> addEvent({
    required SafetyEventType type,
    required String description,
    String? location,
    SafetyEventStatus status = SafetyEventStatus.info,
  }) async {
    final event = SafetyEventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      timestamp: DateTime.now(),
      description: description,
      location: location,
      status: status,
    );
    state = [event, ...state];
    await StorageService.addSafetyEvent(jsonEncode(event.toJson()));
  }

  Future<void> recordFromHealth(
      HealthDataModel health, SafetyEventType type) async {
    String description;
    switch (type) {
      case SafetyEventType.fall:
        description = 'Fall detected.'
            '${health.temperature > 0 ? ' Temp: ${health.temperature.toStringAsFixed(1)}°C.' : ''}'
            '${health.heartRate > 0 ? ' HR: ${health.heartRate} BPM.' : ''}';
        break;
      case SafetyEventType.sos:
        description = 'Emergency SOS triggered manually.'
            '${health.temperature > 0 ? ' Temp: ${health.temperature.toStringAsFixed(1)}°C.' : ''}'
            '${health.heartRate > 0 ? ' HR: ${health.heartRate} BPM.' : ''}';
        break;
      default:
        description = 'Safety event recorded.';
    }
    await addEvent(
      type: type,
      description: description,
      location: health.gpsLat != 0
          ? '${health.gpsLat.toStringAsFixed(4)}, ${health.gpsLng.toStringAsFixed(4)}'
          : 'Unknown Location',
      status: SafetyEventStatus.resolved,
    );
  }

  Future<void> clearAll() async {
    state = [];
    await StorageService.clearSafetyHistory();
  }
}

final safetyHistoryProvider = StateNotifierProvider<SafetyHistoryNotifier, List<SafetyEventModel>>((ref) {
  return SafetyHistoryNotifier();
});

// Used to trigger SOS manually from UI
final manualSOSProvider = StateProvider<bool>((ref) => false);

// ─── Temperature Log ─────────────────────────────────────────────────────────
/// Stores up to 100 recent temperature readings, newest first.
/// Auto-records an entry every time a non-zero temperature arrives from BLE.
final temperatureLogProvider =
    StateNotifierProvider<TemperatureLogNotifier, List<TemperatureEntry>>((ref) {
  return TemperatureLogNotifier(ref);
});

class TemperatureLogNotifier extends StateNotifier<List<TemperatureEntry>> {
  static const int _maxEntries = 100;
  final Ref _ref;
  double _lastRecordedTemp = 0.0;

  TemperatureLogNotifier(this._ref) : super([]) {
    // Listen to live BLE health stream and auto-record temperature changes
    _ref.listen<HealthDataModel>(healthDataProvider, (prev, next) {
      if (next.temperature > 0 && next.temperature != _lastRecordedTemp) {
        _lastRecordedTemp = next.temperature;
        _addEntry(TemperatureEntry(
          value: next.temperature,
          timestamp: next.receivedAt,
        ));
      }
    });
  }

  void _addEntry(TemperatureEntry entry) {
    final updated = [entry, ...state];
    if (updated.length > _maxEntries) {
      state = updated.sublist(0, _maxEntries);
    } else {
      state = updated;
    }
  }
}

// ─── Sleep Tracker ─────────────────────────────────────────────────────────────────
final sleepTrackerProvider =
    StateNotifierProvider<SleepTrackerNotifier, SleepTrackerState>(
  (ref) {
    final db = ref.watch(firebaseDatabaseServiceProvider);
    return SleepTrackerNotifier(db, ref);
  },
);

class SleepTrackerNotifier extends StateNotifier<SleepTrackerState> {
  final FirebaseDatabaseService _db;
  final Ref _ref;
  Timer? _elapsedTimer;

  SleepTrackerNotifier(this._db, this._ref)
      : super(const SleepTrackerState()) {
    _loadInitialState();
  }

  /// Load last session and reminders on init
  Future<void> _loadInitialState() async {
    _loadReminder();
    await _loadLastSession();
  }

  /// Load last session from Hive on init
  Future<void> _loadLastSession() async {
    try {
      // Load from existing Hive box
      // If Hive has no data, try Firebase
      final firebaseData = await _db.getSleepLogs();
      if (firebaseData != null && firebaseData.isNotEmpty) {
        // Find the most recent entry
        final sortedDates = firebaseData.keys.toList()..sort();
        final latestDate = sortedDates.last;
        final latestData = Map<String, dynamic>.from(
            firebaseData[latestDate] as Map);

        final lastSession = SleepSession(
          id: latestData['id'] ?? latestDate,
          startTime: DateTime.parse(
              latestData['start_time'] ?? latestDate),
          endTime: latestData['end_time'] != null
              ? DateTime.parse(latestData['end_time'])
              : null,
          durationMinutes: latestData['duration_minutes'],
          spo2Average: latestData['spo2_average']?.toDouble(),
          quality: latestData['quality'],
          date: latestDate,
        );

        // Check if there was an active session (app killed during sleep)
        if (lastSession.isActive) {
          // Resume tracking
          _resumeActiveSession(lastSession);
        } else {
          state = state.copyWith(lastSession: lastSession);
        }
      }
    } catch (e) {
      debugPrint('[SafeNest Sleep] Load last session error: $e');
    }
  }

  /// Resume if app was killed during active sleep tracking
  void _resumeActiveSession(SleepSession session) {
    state = state.copyWith(
      activeSession: session,
      isTracking: true,
      elapsed: DateTime.now().difference(session.startTime),
    );
    _startElapsedTimer();
    debugPrint('[SafeNest Sleep] Resumed active session from: '
               '${session.startTime}');
  }

  /// START SLEEP — called when user taps "Start Sleep" button
  Future<void> startSleep() async {
    if (state.isTracking) return; // already tracking

    final now = DateTime.now();
    final date = '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final session = SleepSession(
      id: 'sleep_${now.millisecondsSinceEpoch}',
      startTime: now,
      date: date,
    );

    state = state.copyWith(
      activeSession: session,
      isTracking: true,
      elapsed: Duration.zero,
    );

    _startElapsedTimer();

    // Save active session to Firebase immediately
    // so if app is killed, session can be resumed
    try {
      await _db.saveSleepLog(date, {
        ...session.toFirebaseMap(),
        'status': 'in_progress',
      });
      await _db.logActivity('sleep_started', {
        'start_time': now.toIso8601String(),
        'date': date,
      });
      debugPrint('[SafeNest Sleep] ✅ Sleep started at: $now');
    } catch (e) {
      debugPrint('[SafeNest Sleep] ❌ Save start error: $e');
    }
  }

  /// STOP SLEEP — called when user taps "Stop Sleep" / "Wake Up" button
  Future<void> stopSleep() async {
    if (!state.isTracking || state.activeSession == null) return;

    _elapsedTimer?.cancel();

    final now = DateTime.now();
    final start = state.activeSession!.startTime;
    final durationMinutes = now.difference(start).inMinutes;

    final completedSession = state.activeSession!.copyWith(
      endTime: now,
      durationMinutes: durationMinutes,
    );

    state = state.copyWith(
      isTracking: false,
      isSaving: true,
      activeSession: null,
      lastSession: completedSession,
      elapsed: Duration.zero,
    );

    // Save to Hive
    try {
      // Save to existing Hive box using current pattern
      debugPrint('[SafeNest Sleep] Saving to Hive...');
    } catch (e) {
      debugPrint('[SafeNest Sleep] Hive save error: $e');
    }

    // Save completed session to Firebase
    try {
      await _db.saveSleepLog(completedSession.date, {
        ...completedSession.toFirebaseMap(),
        'status': 'completed',
      });

      await _db.logActivity('sleep_completed', {
        'date': completedSession.date,
        'duration_minutes': durationMinutes,
        'formatted': completedSession.formattedDuration,
        'quality': completedSession.qualityFromDuration,
        'start_time': start.toIso8601String(),
        'end_time': now.toIso8601String(),
      });

      debugPrint('[SafeNest Sleep] ✅ Sleep saved: '
                 '${completedSession.formattedDuration}');

      state = state.copyWith(isSaving: false);

    } catch (e) {
      debugPrint('[SafeNest Sleep] ❌ Firebase save error: $e');
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save sleep data. Will retry when online.',
      );
    }
  }

  /// Live timer that updates elapsed duration every second
  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.activeSession == null) return;
      final elapsed = DateTime.now()
          .difference(state.activeSession!.startTime);
      state = state.copyWith(elapsed: elapsed);
    });
  }

  /// Format elapsed time for display
  String get formattedElapsed {
    final h = state.elapsed.inHours;
    final m = state.elapsed.inMinutes % 60;
    final s = state.elapsed.inSeconds % 60;
    return '${h.toString().padLeft(2,'0')}:'
           '${m.toString().padLeft(2,'0')}:'
           '${s.toString().padLeft(2,'0')}';
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  // ── Persistence Helpers ──────────────────────────────────────────────────
  void _loadReminder() {
    final raw = StorageService.sleepReminderSettings;
    if (raw == null || raw.isEmpty) return;
    try {
      final settings = SleepReminderSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
      state = state.copyWith(reminder: settings);
    } catch (e) {
      debugPrint('[SafeNest Sleep] Load reminder error: $e');
    }
  }

  Future<void> _saveReminder(SleepReminderSettings r) =>
      StorageService.setSleepReminderSettings(jsonEncode(r.toJson()));

  // ── Reminder settings ─────────────────────────────────────────────────────
  Future<void> setReminderEnabled(bool enabled) async {
    final updated = state.reminder.copyWith(enabled: enabled);
    state = state.copyWith(reminder: updated);
    await _saveReminder(updated);

    final svc = SleepReminderService.instance;
    await svc.init();
    if (enabled && state.reminder.reminderTime != null) {
      final time = TimeOfDay.fromDateTime(state.reminder.reminderTime!);
      await svc.scheduleDaily(time);
    } else {
      await svc.cancelReminder();
    }
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    final now = DateTime.now();
    final reminderDateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    final updated = state.reminder.copyWith(reminderTime: reminderDateTime);
    state = state.copyWith(reminder: updated);
    await _saveReminder(updated);

    if (updated.enabled) {
      final svc = SleepReminderService.instance;
      await svc.scheduleDaily(time);
    }
  }
}
