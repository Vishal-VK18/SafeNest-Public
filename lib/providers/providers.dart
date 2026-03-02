import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/health_data_model.dart';
import '../models/device_status_model.dart';
import '../models/pregnancy_model.dart';
import '../models/safety_event_model.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

// ─── BLE Service singleton ──────────────────────────────────────────────────
final bleServiceProvider = Provider<BleService>((_) => BleService.instance);

// ─── Health data stream ──────────────────────────────────────────────────────
/// Streams the latest parsed BLE health packet.
final healthStreamProvider = StreamProvider<HealthDataModel>((ref) {
  final ble = ref.read(bleServiceProvider);
  return ble.healthStream;
});

/// Latest health snapshot — starts empty, updated only by real BLE data.
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

// ─── Device status stream ────────────────────────────────────────────────────
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

// ─── BLE Scan state ──────────────────────────────────────────────────────────
/// True while a manual scan is in progress.
final bleScanningProvider = StreamProvider<bool>((ref) {
  return ref.read(bleServiceProvider).scanningStream;
});

/// Live list of discovered BLE devices during manual scan.
final bleScanResultsProvider = StreamProvider<List<ScanResult>>((ref) {
  return ref.read(bleServiceProvider).scanResultsStream;
});

// ─── Pregnancy ───────────────────────────────────────────────────────────────
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

// ─── Fall alert state (for UI dismissal) ────────────────────────────────────
final fallAlertActiveProvider = StateProvider<bool>((ref) {
  final health = ref.watch(healthDataProvider);
  return health.fallDetected;
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
      status: SafetyEventStatus.resolved, // UI shows Resolved as default for past events
    );
  }
}

final safetyHistoryProvider = StateNotifierProvider<SafetyHistoryNotifier, List<SafetyEventModel>>((ref) {
  return SafetyHistoryNotifier();
});

// Used to trigger SOS manually from UI
final manualSOSProvider = StateProvider<bool>((ref) => false);
