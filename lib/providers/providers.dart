// lib/providers/providers.dart
// Single file exposing all Riverpod providers for SafeNest.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/health_data_model.dart';
import '../models/device_status_model.dart';
import '../models/pregnancy_model.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';

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
