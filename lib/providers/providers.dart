// lib/providers/providers.dart
// Single file exposing all Riverpod providers for SafeNest.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_data_model.dart';
import '../models/device_status_model.dart';
import '../models/pregnancy_model.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';

// ─── BLE Service singleton ──────────────────────────────────────────────────
final bleServiceProvider = Provider<BleService>((_) => BleService.instance);

// ─── Health data stream ──────────────────────────────────────────────────────
/// Streams the latest parsed BLE health packet. Falls back to cached data.
final healthStreamProvider = StreamProvider<HealthDataModel>((ref) {
  final ble = ref.read(bleServiceProvider);
  return ble.healthStream;
});

/// Latest health snapshot (non-async, with fallback from storage)
final healthDataProvider = StateNotifierProvider<HealthDataNotifier, HealthDataModel>(
  (ref) => HealthDataNotifier(ref),
);

class HealthDataNotifier extends StateNotifier<HealthDataModel> {
  final Ref _ref;
  HealthDataNotifier(this._ref) : super(_loadCached()) {
    // Subscribe to BLE stream
    _ref.read(bleServiceProvider).healthStream.listen((packet) {
      state = packet;
    });
  }

  static HealthDataModel _loadCached() {
    final json = StorageService.lastHealthPacket;
    if (json != null) return HealthDataModel.fromJsonString(json);
    return HealthDataModel.mock();
  }
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

// ─── Pregnancy ───────────────────────────────────────────────────────────────
final pregnancyProvider =
    StateNotifierProvider<PregnancyNotifier, PregnancyModel>(
  (ref) => PregnancyNotifier(),
);

class PregnancyNotifier extends StateNotifier<PregnancyModel> {
  PregnancyNotifier()
      : super(PregnancyModel(
          pregnancyWeek: StorageService.pregnancyWeek,
          userName:      StorageService.userName,
        ));

  Future<void> updateWeek(int week) async {
    await StorageService.setPregnancyWeek(week);
    state = state.copyWith(pregnancyWeek: week);
  }

  Future<void> updateName(String name) async {
    await StorageService.setUserName(name);
    state = state.copyWith(userName: name);
  }
}

// ─── Fall alert state (for UI dismissal) ────────────────────────────────────
final fallAlertActiveProvider = StateProvider<bool>((ref) {
  // Automatically becomes true when health data shows fall_detected
  final health = ref.watch(healthDataProvider);
  return health.fallDetected;
});
