// lib/providers/system_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/system_service.dart';

final systemServiceProvider = Provider<SystemService>((ref) => SystemService.instance);

final bluetoothStateProvider = StreamProvider<BluetoothAdapterState>((ref) {
  final system = ref.watch(systemServiceProvider);
  return system.bluetoothState;
});

final wifiConnectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final system = ref.watch(systemServiceProvider);
  return system.connectivityStream;
});

final networkNameProvider = FutureProvider<String>((ref) {
  final system = ref.watch(systemServiceProvider);
  // We trigger this when connectivity changes
  ref.watch(wifiConnectivityProvider);
  return system.getNetworkName();
});
