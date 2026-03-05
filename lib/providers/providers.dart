import 'dart:convert';
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
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../models/temperature_entry.dart';

// â”€â”€â”€ BLE Service singleton â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final bleServiceProvider = Provider<BleService>((_) => BleService.instance);

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
  HealthDataNotifier(this._ref) : super(HealthDataModel.empty()) {
    // Subscribe to real BLE stream only
    _ref.read(bleServiceProvider).healthStream.listen((packet) {
      state = packet;
    });
  }

  void reset() => state = HealthDataModel.empty();
}

// â”€â”€â”€ Device status stream â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final deviceStreamProvider = StreamProvider<DeviceStatusModel>((ref) {
  return ref.read(bleServiceProvider).deviceStream;
});

final deviceStatusProvider =
    StateNotifierProvider<DeviceStatusNotifier, DeviceStatusModel>(
  (ref) => DeviceStatusNotifier(ref),
);

class DeviceStatusNotifier extends StateNotifier<DeviceStatusModel> {
  final Ref _ref;
  DeviceStatusNotifier(this._ref) : super(DeviceStatusModel.initial()) {
    _ref.read(bleServiceProvider).deviceStream.listen((status) {
      state = status;
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
  (ref) => PregnancyNotifier(),
);

class PregnancyNotifier extends StateNotifier<PregnancyModel> {
  PregnancyNotifier()
      : super(PregnancyModel(
          startDate:  StorageService.pregnancyStartDate,
          manualWeek: StorageService.pregnancyWeek,
          userName:   StorageService.userName,
        ));

  Future<void> updateStartDate(DateTime date) async {
    await StorageService.setPregnancyStartDate(date);
    state = state.copyWith(startDate: date);
  }

  Future<void> updateWeek(int week) async {
    await StorageService.setPregnancyWeek(week);
    state = state.copyWith(manualWeek: week);
  }

  Future<void> updateName(String name) async {
    await StorageService.setUserName(name);
    state = state.copyWith(userName: name);
  }
}

// â”€â”€â”€ Fall alert state (for UI dismissal) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final fallAlertActiveProvider = StateProvider<bool>((ref) {
  final health = ref.watch(healthDataProvider);
  return health.fallDetected;
});

// â”€â”€â”€ Caregivers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final contactsProvider = StateNotifierProvider<ContactsNotifier, List<ContactModel>>((ref) {
  return ContactsNotifier();
});

class ContactsNotifier extends StateNotifier<List<ContactModel>> {
  ContactsNotifier() : super([]);

  void addContact(ContactModel contact) {
    state = [...state, contact];
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
  }
}

// â”€â”€â”€ Hydration Logic Engine â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final hydrationProvider = StateNotifierProvider<HydrationNotifier, HydrationModel>((ref) {
  return HydrationNotifier();
});

class HydrationNotifier extends StateNotifier<HydrationModel> {
  HydrationNotifier()
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
  }
}


// â”€â”€â”€ Sleep & Oxygen Logic Engine â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final sleepOxygenProvider = StateNotifierProvider<SleepOxygenNotifier, SleepOxygenModel>((ref) {
  return SleepOxygenNotifier();
});

class SleepOxygenNotifier extends StateNotifier<SleepOxygenModel> {
  SleepOxygenNotifier() : super(StorageService.sleepData != null 
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
  }
}

// â”€â”€â”€ Smart Appointment System â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final appointmentProvider = StateNotifierProvider<AppointmentNotifier, List<AppointmentModel>>((ref) {
  return AppointmentNotifier();
});

class AppointmentNotifier extends StateNotifier<List<AppointmentModel>> {
  AppointmentNotifier() : super(StorageService.appointments != null 
    ? AppointmentModel.decodeList(StorageService.appointments!)
    : []);

  void addAppointment(AppointmentModel appt) {
    state = [...state, appt];
    _save();
  }

  void updateAppointment(AppointmentModel updated) {
    state = [
      for (final a in state)
        if (a.id == updated.id) updated else a
    ];
    _save();
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
  }

  void deleteAppointment(String id) {
    state = state.where((a) => a.id != id).toList();
    _save();
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
      state = historyJson.map((s) => SafetyEventModel.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
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

  Future<void> recordFromHealth(HealthDataModel health, SafetyEventType type) async {
    await addEvent(
      type: type,
      description: type == SafetyEventType.fall 
          ? "Fall detected near your location." 
          : "Emergency SOS triggered manually.",
      location: health.gpsLat != 0 ? "${health.gpsLat.toStringAsFixed(4)}, ${health.gpsLng.toStringAsFixed(4)}" : "Unknown Location",
      status: SafetyEventStatus.resolved,
    );
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
