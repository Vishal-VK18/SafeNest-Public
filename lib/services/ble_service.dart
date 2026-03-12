import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/health_data_model.dart';
import '../models/device_status_model.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'background_service.dart';
import '../models/safety_event_model.dart';

/// Central BLE manager for SafeNest.
///
/// – Scans for watch + SIM unit (prefixed device names).
/// – Connects, subscribes to characteristic, parses JSON packets.
/// – Heartbeat watchdog (5 s) — triggers disconnect notification.
/// – Auto-reconnect with back-off.
class BleService {
  BleService._();
  static final BleService instance = BleService._();

  // ─── Streams ─────────────────────────────────────────────────────────────────
  final _healthCtrl = StreamController<HealthDataModel>.broadcast();
  Stream<HealthDataModel> get healthStream => _healthCtrl.stream;

  final _deviceCtrl = StreamController<DeviceStatusModel>.broadcast();
  Stream<DeviceStatusModel> get deviceStream => _deviceCtrl.stream;

  final _scanResultsCtrl = StreamController<List<ScanResult>>.broadcast();
  Stream<List<ScanResult>> get scanResultsStream => _scanResultsCtrl.stream;

  final _scanningCtrl = StreamController<bool>.broadcast();
  Stream<bool> get scanningStream => _scanningCtrl.stream;

  // ─── State ────────────────────────────────────────────────────────────────────
  DeviceStatusModel _deviceStatus = DeviceStatusModel.initial();
  HealthDataModel   _lastHealth   = HealthDataModel.empty();
  BluetoothDevice?  _watchDevice;
  BluetoothDevice?  _simDevice;
  Timer?            _heartbeatTimer;
  Timer?            _reconnectTimer;
  DateTime?         _lastPacketTime;
  bool              _destroyed = false;
  bool              _isScanning = false;

  DateTime? _lastDisconnectNotifTime;
  DateTime? _lastTempNotifTime;
  bool _tempAlertActive = false;

  final List<ScanResult> _scanResults = [];

  int _reconnectAttempts = 0;
  static const _maxReconnectDelaySec = 10;

  // ─── Start / Stop ────────────────────────────────────────────────────────────
  Future<void> start() async {
    if (_isBleSupported) {
      await _startAutoScan();
    } else {
      debugPrint('[BLE] Support not available on this platform.');
    }
  }

  bool get _isBleSupported => Platform.isAndroid || Platform.isIOS;

  void dispose() {
    _destroyed = true;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _watchDevice?.disconnect();
    _simDevice?.disconnect();
    _healthCtrl.close();
    _deviceCtrl.close();
    _scanResultsCtrl.close();
    _scanningCtrl.close();
  }

  // ─── Auto scan (background, on start) ───────────────────────────────────────
  Future<void> _startAutoScan() async {
    debugPrint('[BLE] Starting auto-scan...');
    _updateWatchStatus(ConnectionStatus.scanning);

    // Try direct reconnect to cached device first — skips scan entirely
    final cachedId = StorageService.pairedWatchId;
    if (cachedId != null && cachedId.isNotEmpty) {
      try {
        debugPrint('[BLE] Trying direct reconnect to: $cachedId');

        // Check if already connected
        for (final d in FlutterBluePlus.connectedDevices) {
          if (d.remoteId.str == cachedId) {
            debugPrint('[BLE] Already connected — subscribing directly');
            await _connectToWatch(d);
            return;
          }
        }

        // Try connecting directly without scanning
        final device = BluetoothDevice(remoteId: DeviceIdentifier(cachedId));
        await _connectToWatch(device);
        return;
      } catch (e) {
        debugPrint('[BLE] Direct reconnect failed — falling back to scan: $e');
      }
    }

    await _runScan(autoConnect: true);
  }

  // ─── Manual scan (UI-initiated, shows all SafeNest devices) ─────────────────
  Future<void> startManualScan() async {
    if (!_isBleSupported) return;
    if (_isScanning) {
      await FlutterBluePlus.stopScan();
    }
    _scanResults.clear();
    _scanResultsCtrl.add([]);
    _scanningCtrl.add(true);
    _isScanning = true;
    debugPrint('[BLE] Starting manual scan...');

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: AppConstants.scanTimeoutSec),
      );

      FlutterBluePlus.scanResults.listen((results) {
        // Show any SafeNest device (or any device if none found yet)
        final filtered = results.where((r) =>
            r.device.platformName.startsWith(AppConstants.safeNestPrefix) ||
            r.device.platformName.isNotEmpty,
        ).toList();
        _scanResults
          ..clear()
          ..addAll(filtered);
        if (!_scanResultsCtrl.isClosed) {
          _scanResultsCtrl.add(List.from(_scanResults));
        }
      });

      // Wait for scan to finish
      await FlutterBluePlus.isScanning
          .firstWhere((scanning) => !scanning)
          .timeout(
        const Duration(seconds: AppConstants.scanTimeoutSec + 2),
        onTimeout: () => false,
      );
    } catch (e) {
      debugPrint('[BLE] Manual scan error: $e');
    } finally {
      _isScanning = false;
      if (!_scanningCtrl.isClosed) _scanningCtrl.add(false);
    }
  }

  // ─── Connect to a user-selected device ──────────────────────────────────────
  Future<void> connectToDevice(BluetoothDevice device) async {
    final name = device.platformName;
    if (name.startsWith(AppConstants.watchNamePrefix)) {
      await _connectToWatch(device);
    } else if (name.startsWith(AppConstants.simUnitNamePrefix)) {
      await _connectToSim(device);
    } else {
      // Unknown device — try as watch
      await _connectToWatch(device);
    }
  }

  // ─── Internal BLE Scan (auto-mode) ───────────────────────────────────────────
  Future<void> _runScan({bool autoConnect = false}) async {
    if (!_isBleSupported) return;
    try {
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: AppConstants.scanTimeoutSec),
      );

      FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.device.platformName;
          if (autoConnect) {
            if (name.startsWith(AppConstants.watchNamePrefix) &&
                _watchDevice == null) {
              _connectToWatch(r.device, rssi: r.rssi);
            }
            if (name.startsWith(AppConstants.simUnitNamePrefix) &&
                _simDevice == null) {
              _connectToSim(r.device, rssi: r.rssi);
            }
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

      // Battery is unknown until read from BLE characteristic
      _updateDeviceStatus(_deviceStatus.copyWith(
        watch: DeviceInfo(
          id:             device.remoteId.str,
          name:           device.platformName.isNotEmpty
              ? device.platformName
              : 'SafeNest Watch',
          status:         ConnectionStatus.connected,
          batteryPercent: 0,   // will be updated when BLE battery attribute is read
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
          name:           device.platformName.isNotEmpty
              ? device.platformName
              : 'SafeNest SIM',
          status:         ConnectionStatus.connected,
          batteryPercent: 0,   // unknown until read from BLE
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
                final raw = utf8.decode(bytes, allowMalformed: true).trim();
                _handleBleValue(raw);
              });
              debugPrint('[BLE] Subscribed to health characteristic');
              return;
            }
          }
        }
      }
      debugPrint('[BLE] Characteristic not found — update UUIDs in constants.dart');
    } catch (e) {
      debugPrint('[BLE] Service discovery error: $e');
    }
  }

  // ─── Handle raw BLE value (comma-separated: "36.75,0") ───────────────────
  void _handleBleValue(String raw) {
    if (raw.isEmpty) return;

    final parts = raw.split(',');

    // Part 0 — temperature
    final temp = double.tryParse(parts[0].trim());
    if (temp == null) return;

    // Part 1 — fall
    final fall = parts.length >= 2 && parts[1].trim() == '1';

    // Part 2 — tempAlert: 0=normal, 1=high
    final tempAlert = parts.length >= 3
        ? (int.tryParse(parts[2].trim()) ?? 0)
        : 0;

    // Part 3 — SIM signal 0-100 percent sent directly from ESP
    int simSignal = 0;
    if (parts.length >= 4) {
      simSignal = int.tryParse(parts[3].trim()) ?? 0;
    }

    // Part 4 — network type string: "4G", "3G", "2G", "—"
    final networkType = parts.length >= 5
        ? parts[4].trim()
        : _lastHealth.networkType;

    // Part 5 — band battery percent (0-100)
    final bandBattery = parts.length > 5
        ? (int.tryParse(parts[5].trim()) ?? _lastHealth.bandBattery)
        : _lastHealth.bandBattery;

    // Part 6 — SIM battery percent (0-100)
    final simBattery = parts.length > 6
        ? (int.tryParse(parts[6].trim()) ?? _lastHealth.simBattery)
        : _lastHealth.simBattery;

    final model = _lastHealth.copyWith(
      temperature: temp,
      fallDetected: fall,
      tempAlert: tempAlert,
      simSignal: simSignal,
      networkType: networkType,
      bandBattery: bandBattery,
      simBattery: simBattery,
      receivedAt: DateTime.now(),
    );
    _onPacketReceived(model);
  }

  // ─── Packet received ─────────────────────────────────────────────────────────
  void _onPacketReceived(HealthDataModel model) {
    _lastPacketTime = DateTime.now();
    _lastHealth = model;
    if (!_healthCtrl.isClosed) _healthCtrl.add(model);

    // Update watch — battery + signal together
    if (_deviceStatus.watch.isConnected) {
      _updateDeviceStatus(_deviceStatus.copyWith(
        watch: _deviceStatus.watch.copyWith(
          batteryPercent: model.bandBattery > 0
              ? model.bandBattery
              : _deviceStatus.watch.batteryPercent,
          signalLevel: model.simSignal > 0
              ? model.simSignal
              : _deviceStatus.watch.signalLevel,
          lastSeen: DateTime.now(),
        ),
      ));
    }

    // Update SIM unit — battery + signal together
    if (_deviceStatus.watch.isConnected) {
      _updateDeviceStatus(_deviceStatus.copyWith(
        simUnit: _deviceStatus.simUnit.copyWith(
          batteryPercent: model.simBattery > 0
              ? model.simBattery
              : _deviceStatus.simUnit.batteryPercent,
          signalLevel: model.simSignal > 0
              ? model.simSignal
              : _deviceStatus.simUnit.signalLevel,
          lastSeen: DateTime.now(),
        ),
      ));
    }

    // Persist to local cache
    StorageService.setLastHealthPacket(model.toJsonString());
    if (model.gpsLat != 0) {
      StorageService.setLastGps(model.gpsLat, model.gpsLng);
    }

    // Fall — fires every time a NEW fall is detected (leading edge only)
    if (model.fallDetected && !_lastHealth.fallDetected) {
      NotificationService.showFallAlert();
      BackgroundService.showFallNotification();
      _recordEvent(SafetyEventType.fall,
          'Fall detected. Temp: ${model.temperature.toStringAsFixed(1)}°C.'
          '${model.heartRate > 0 ? ' HR: ${model.heartRate} BPM.' : ''}');
    }

    if (!model.isHeartRateNormal && model.heartRate > 0 &&
        (model.heartRate != _lastHealth.heartRate)) {
      NotificationService.showAbnormalHeartRate(model.heartRate);
      _recordEvent(SafetyEventType.vitals,
          'Abnormal heart rate: ${model.heartRate} BPM detected.');
    }

    // High temp — 33°C threshold, notify continuously on each new trigger
    final isHighTemp = model.temperature >= AppConstants.tempSafetyThreshold
        || model.tempAlert == 1;
    if (isHighTemp && !_tempAlertActive) {
      _tempAlertActive = true;
      NotificationService.showHighTemperature(model.temperature);
      BackgroundService.showTempNotification(model.temperature);
    } else if (!isHighTemp) {
      _tempAlertActive = false;
    }

    // Low temp — notify continuously on each new trigger
    if (model.tempAlert == -1 && _lastHealth.tempAlert != -1) {
      NotificationService.showLowTemperature(model.temperature);
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
    // Reset health data battery fields
    _lastHealth = _lastHealth.copyWith(bandBattery: 0, simBattery: 0);
    if (!_healthCtrl.isClosed) _healthCtrl.add(_lastHealth);
    // Clear battery + signal so UI shows disconnected state, not stale values
    _updateDeviceStatus(_deviceStatus.copyWith(
      watch: _deviceStatus.watch.copyWith(
        status: ConnectionStatus.disconnected,
        batteryPercent: 0,
        signalLevel: 0,
      ),
    ));
    _maybeSendDisconnectNotif('SafeNest Watch');
    _scheduleReconnect(() => _startAutoScan());
  }

  void _onSimDisconnected() {
    debugPrint('[BLE] SIM unit disconnected');
    _simDevice = null;
    // Clear battery so UI shows disconnected state, not stale values
    _updateDeviceStatus(_deviceStatus.copyWith(
      simUnit: _deviceStatus.simUnit.copyWith(
        status: ConnectionStatus.disconnected,
        batteryPercent: 0,
        signalLevel: 0,
      ),
    ));
    _maybeSendDisconnectNotif('SafeNest SIM');
    _scheduleReconnect(() => _startAutoScan());
  }

  void _maybeSendDisconnectNotif(String deviceName) {
    final hasPaired = StorageService.pairedWatchId != null &&
        StorageService.pairedWatchId!.isNotEmpty;
    if (!hasPaired) return;

    final now = DateTime.now();
    if (_lastDisconnectNotifTime == null ||
        now.difference(_lastDisconnectNotifTime!).inMinutes >=
            AppConstants.disconnectCooldownMin) {
      _lastDisconnectNotifTime = now;
      NotificationService.showDeviceDisconnected(deviceName);
    } else {
      debugPrint('[BLE] Disconnect notif suppressed — cooldown active');
    }
  }

  void _recordEvent(SafetyEventType type, String description) {
    // Use a global container reference to add to safety history
    _eventBuffer.add(_PendingEvent(type: type, description: description));
  }

  final List<_PendingEvent> _eventBuffer = [];

  /// Called by the app's ProviderContainer to flush buffered events into state.
  Future<void> flushEvents(
      Future<void> Function(SafetyEventType, String) onEvent) async {
    for (final e in List.from(_eventBuffer)) {
      await onEvent(e.type, e.description);
      _eventBuffer.remove(e);
    }
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
    await _startAutoScan();
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
    if (!_destroyed && !_deviceCtrl.isClosed) _deviceCtrl.add(updated);
  }

  int _rssiToLevel(int rssi) {
    if (rssi >= -50) return 100;
    if (rssi >= -70) return 75;
    if (rssi >= -85) return 50;
    return 25;
  }
}

class _PendingEvent {
  final SafetyEventType type;
  final String description;
  const _PendingEvent({required this.type, required this.description});
}
