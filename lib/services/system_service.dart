// lib/services/system_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';

class SystemService {
  SystemService._();
  static final SystemService instance = SystemService._();

  final _connectivity = Connectivity();
  
  // ─── Permissions ──────────────────────────────────────────────────────────
  Future<void> requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
        Permission.notification,
      ].request();

      debugPrint('[System] Permission statuses: $statuses');
    }
  }

  // ─── Bluetooth ────────────────────────────────────────────────────────────
  Stream<BluetoothAdapterState> get bluetoothState => FlutterBluePlus.adapterState;

  Future<void> turnOnBluetooth() async {
    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        debugPrint('[System] Could not turn on Bluetooth automatically: $e');
        await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
      }
    } else if (Platform.isIOS) {
      await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
    }
  }

  // ─── WiFi ─────────────────────────────────────────────────────────────────
  Stream<List<ConnectivityResult>> get connectivityStream => _connectivity.onConnectivityChanged;

  Future<void> openWiFiSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.wifi);
  }

  Future<String> getNetworkName() async {
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.wifi)) {
      // Note: Getting the SSID requires location permission and extra setup on Android/iOS.
      // For now, we'll return a generic "Connected to WiFi" if SSID is not easily available.
      return "Connected to WiFi";
    }
    return "Disconnected";
  }
}
