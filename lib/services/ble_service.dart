// lib/services/ble_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/health_data_model.dart';
import '../models/device_status_model.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

/// Central BLE manager for SafeNest.
///
/// – Scans for watch + SIM unit (prefixed device names).
/// – Connects, subscribes to characteristic, parses JSON packets.
/// – Heartbeat watchdog (5 s) — triggers disconnect notification.
/// – Auto-reconnect with back-off.
/// – In mock mode, streams synthetic health data every 3 s.
class BleService {
  BleService._();
  static final BleService instance = BleService._();

  // ─── Streams ─────────────────────────────────────────────────────────────────
  final _healthCtrl = StreamController<HealthDataModel>.broadcast();
  Stream<HealthDataModel> get healthStream => _healthCtrl.stream;

  final _deviceCtrl = StreamController<DeviceStatusModel>.broadcast();
  Stream<DeviceStatusModel> get deviceStream => _deviceCtrl.stream;

  // ─── State ────────────────────────────────────────────────────────────────────
  DeviceStatusModel _deviceStatus = DeviceStatusModel.initial();
  BluetoothDevice?  _watchDevice;
  BluetoothDevice?  _simDevice;
  Timer?            _heartbeatTimer;
  Timer?            _reconnectTimer;
  Timer?            _mockTimer;
  DateTime?         _lastPacketTime;
  bool              _destroyed = false;

  int _reconnectAttempts = 0;
  static const _maxReconnectDelaySec = 10;

  // ─── Start / Stop ────────────────────────────────────────────────────────────
  Future<void> start() async {
    if (AppConstants.useMockData) {
      _startMockMode();
      return;
    }
    await _startScan();
  }

  void dispose() {
    _destroyed = true;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _mockTimer?.cancel();
    _watchDevice?.disconnect();
    _simDevice?.disconnect();
    _healthCtrl.close();
    _deviceCtrl.close();
  }

  // ─── Mock / Demo mode ────────────────────────────────────────────────────────
  void _startMockMode() {
    debugPrint('[BLE] *** MOCK MODE ACTIVE ***');

    // Immediately emit "connected" status for both devices
    _updateDeviceStatus(_deviceStatus.copyWith(
      watch: DeviceInfo(
        id:             'mock-watch-001',
        name:           'Pregnancy Watch',
        status:         ConnectionStatus.connected,
        batteryPercent: 85,
        signalLevel:    90,
        lastSeen:       DateTime.now(),
      ),
      simUnit: DeviceInfo(
        id:             'mock-sim-001',
        name:           'SIM Unit Pro',
        status:         ConnectionStatus.connected,
        batteryPercent: 72,
        signalLevel:    75,
        lastSeen:       DateTime.now(),
      ),
    ));

    // Stream a new mock packet every 3 seconds with slight variation
    final rng = Random();
    _mockTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_destroyed) return;
      final baseHr    = 82;
      final hr        = baseHr + rng.nextInt(6) - 3;
      final baseTemp  = 36.7;
      final temp      = baseTemp + (rng.nextInt(4) - 2) * 0.1;

      final packet = HealthDataModel.mock().copyWith(
        heartRate:   hr,
        temperature: double.parse(temp.toStringAsFixed(1)),
        receivedAt:  DateTime.now(),
      );
      _onPacketReceived(packet);
    });
  }

  // ─── BLE Scan ────────────────────────────────────────────────────────────────
  Future<void> _startScan() async {
    debugPrint('[BLE] Starting scan...');
    _updateWatchStatus(ConnectionStatus.scanning);

    try {
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: AppConstants.scanTimeoutSec),
      );

      FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.device.platformName;
          if (name.startsWith(AppConstants.watchNamePrefix) &&
              _watchDevice == null) {
            _connectToWatch(r.device, rssi: r.rssi);
          }
          if (name.startsWith(AppConstants.simUnitNamePrefix) &&
              _simDevice == null) {
            _connectToSim(r.device, rssi: r.rssi);
          }
        }
      });
    } catch (e) {
      debugPrint('[BLE] Scan error: $e');
    }
  }

  // ─── Connect to Watch ────────────────────────────────────────────────────────
  Future<void> _connectToWatch(BluetoothDevice device, {int rssi = -70}) async {
    debugPrint('[BLE] Connecting to watch: ${device.platformName}');
    _watchDevice = device;
    _updateWatchStatus(ConnectionStatus.connecting);

    try {
      await device.connect(timeout: const Duration(seconds: 15));
      final signalLevel = _rssiToLevel(rssi);

      _updateDeviceStatus(_deviceStatus.copyWith(
        watch: DeviceInfo(
          id:             device.remoteId.str,
          name:           'Pregnancy Watch',
          status:         ConnectionStatus.connected,
          batteryPercent: 85,
          signalLevel:    signalLevel,
          lastSeen:       DateTime.now(),
        ),
      ));

      await StorageService.setPairedWatchId(device.remoteId.str);
      await _subscribeToCharacteristic(device);
      _resetReconnectAttempts();
      _startHeartbeatWatchdog();

      // Listen for disconnection
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _onWatchDisconnected();
        }
      });
    } catch (e) {
      debugPrint('[BLE] Watch connect error: $e');
      _onWatchDisconnected();
    }
  }

  // ─── Connect to SIM ──────────────────────────────────────────────────────────
  Future<void> _connectToSim(BluetoothDevice device, {int rssi = -70}) async {
    debugPrint('[BLE] Connecting to SIM unit: ${device.platformName}');
    _simDevice = device;
    _updateSimStatus(ConnectionStatus.connecting);

    try {
      await device.connect(timeout: const Duration(seconds: 15));
      final signalLevel = _rssiToLevel(rssi);

      _updateDeviceStatus(_deviceStatus.copyWith(
        simUnit: DeviceInfo(
          id:             device.remoteId.str,
          name:           'SIM Unit Pro',
          status:         ConnectionStatus.connected,
          batteryPercent: 72,
          signalLevel:    signalLevel,
          lastSeen:       DateTime.now(),
        ),
      ));

      await StorageService.setPairedSimId(device.remoteId.str);

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _onSimDisconnected();
        }
      });
    } catch (e) {
      debugPrint('[BLE] SIM connect error: $e');
      _onSimDisconnected();
    }
  }

  // ─── Characteristic subscription ────────────────────────────────────────────
  Future<void> _subscribeToCharacteristic(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() ==
            AppConstants.bleServiceUUID.toLowerCase()) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() ==
                AppConstants.bleCharacteristicUUID.toLowerCase()) {
              await char.setNotifyValue(true);
              char.onValueReceived.listen((bytes) {
                final raw = utf8.decode(bytes, allowMalformed: true);
                final model = HealthDataModel.fromJsonString(raw);
                _onPacketReceived(model);
              });
              debugPrint('[BLE] Subscribed to characteristic');
              return;
            }
          }
        }
      }
      debugPrint('[BLE] Characteristic not found — check UUIDs in constants.dart');
    } catch (e) {
      debugPrint('[BLE] Service discovery error: $e');
    }
  }

  // ─── Packet received ─────────────────────────────────────────────────────────
  void _onPacketReceived(HealthDataModel model) {
    _lastPacketTime = DateTime.now();
    _healthCtrl.add(model);

    // Persist to local cache
    StorageService.setLastHealthPacket(model.toJsonString());
    if (model.gpsLat != 0) {
      StorageService.setLastGps(model.gpsLat, model.gpsLng);
    }

    // Check thresholds → notifications
    if (model.fallDetected) {
      NotificationService.showFallAlert();
    }
    if (!model.isHeartRateNormal && model.heartRate > 0) {
      NotificationService.showAbnormalHeartRate(model.heartRate);
    }
    if (!model.isTemperatureNormal && model.temperature > 0) {
      NotificationService.showHighTemperature(model.temperature);
    }
  }

  // ─── Heartbeat watchdog ──────────────────────────────────────────────────────
  void _startHeartbeatWatchdog() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      Duration(seconds: AppConstants.heartbeatIntervalSec),
      (_) {
        if (_lastPacketTime == null) return;
        final elapsed = DateTime.now().difference(_lastPacketTime!).inSeconds;
        if (elapsed > AppConstants.heartbeatIntervalSec * 2) {
          debugPrint('[BLE] Heartbeat missed — stale connection');
          _onWatchDisconnected();
        }
      },
    );
  }

  // ─── Disconnect handlers ─────────────────────────────────────────────────────
  void _onWatchDisconnected() {
    debugPrint('[BLE] Watch disconnected');
    _heartbeatTimer?.cancel();
    _watchDevice = null;
    _updateWatchStatus(ConnectionStatus.disconnected);
    NotificationService.showDeviceDisconnected('Pregnancy Watch');
    _scheduleReconnect(() => _startScan());
  }

  void _onSimDisconnected() {
    debugPrint('[BLE] SIM unit disconnected');
    _simDevice = null;
    _updateSimStatus(ConnectionStatus.disconnected);
    NotificationService.showSimError();
    _scheduleReconnect(() => _startScan());
  }

  // ─── Auto-reconnect ──────────────────────────────────────────────────────────
  void _scheduleReconnect(VoidCallback action) {
    if (_destroyed) return;
    _reconnectAttempts++;
    final delaySec = min(
      AppConstants.autoReconnectDelaySec * _reconnectAttempts,
      _maxReconnectDelaySec,
    );
    debugPrint('[BLE] Reconnect in ${delaySec}s (attempt $_reconnectAttempts)');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySec), action);
  }

  void _resetReconnectAttempts() => _reconnectAttempts = 0;

  /// Allows UI to manually trigger a reconnect attempt.
  Future<void> reconnect() async {
    _reconnectAttempts = 0;
    if (AppConstants.useMockData) {
      _startMockMode();
    } else {
      await _startScan();
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  void _updateWatchStatus(ConnectionStatus s) {
    _updateDeviceStatus(_deviceStatus.copyWith(
      watch: _deviceStatus.watch.copyWith(status: s),
    ));
  }

  void _updateSimStatus(ConnectionStatus s) {
    _updateDeviceStatus(_deviceStatus.copyWith(
      simUnit: _deviceStatus.simUnit.copyWith(status: s),
    ));
  }

  void _updateDeviceStatus(DeviceStatusModel updated) {
    _deviceStatus = updated;
    if (!_destroyed) _deviceCtrl.add(updated);
  }

  int _rssiToLevel(int rssi) {
    if (rssi >= -50) return 100;
    if (rssi >= -70) return 75;
    if (rssi >= -85) return 50;
    return 25;
  }
}
