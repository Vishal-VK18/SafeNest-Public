// lib/models/device_status_model.dart

enum ConnectionStatus { disconnected, scanning, connecting, connected }

class DeviceInfo {
  final String id;
  final String name;
  final ConnectionStatus status;
  final int batteryPercent;
  final int signalLevel; // 0–100 (RSSI normalized)
  final DateTime? lastSeen;

  const DeviceInfo({
    required this.id,
    required this.name,
    required this.status,
    this.batteryPercent = 0,
    this.signalLevel    = 0,
    this.lastSeen,
  });

  factory DeviceInfo.empty(String name) => DeviceInfo(
    id:     '',
    name:   name,
    status: ConnectionStatus.disconnected,
  );

  bool get isConnected  => status == ConnectionStatus.connected;
  bool get isScanning   => status == ConnectionStatus.scanning;
  bool get isConnecting => status == ConnectionStatus.connecting;

  String get statusLabel {
    switch (status) {
      case ConnectionStatus.connected:    return 'Connected';
      case ConnectionStatus.connecting:   return 'Connecting...';
      case ConnectionStatus.scanning:     return 'Scanning...';
      case ConnectionStatus.disconnected: return 'Disconnected';
    }
  }

  String get signalLabel {
    if (signalLevel >= 75) return 'Excellent';
    if (signalLevel >= 50) return 'Good';
    if (signalLevel >= 25) return 'Fair';
    return 'Poor';
  }

  DeviceInfo copyWith({
    String? id,
    String? name,
    ConnectionStatus? status,
    int? batteryPercent,
    int? signalLevel,
    DateTime? lastSeen,
  }) => DeviceInfo(
    id:             id             ?? this.id,
    name:           name           ?? this.name,
    status:         status         ?? this.status,
    batteryPercent: batteryPercent ?? this.batteryPercent,
    signalLevel:    signalLevel    ?? this.signalLevel,
    lastSeen:       lastSeen       ?? this.lastSeen,
  );
}

class DeviceStatusModel {
  final DeviceInfo watch;
  final DeviceInfo simUnit;

  const DeviceStatusModel({
    required this.watch,
    required this.simUnit,
  });

  factory DeviceStatusModel.initial() => DeviceStatusModel(
    watch:   DeviceInfo.empty('Pregnancy Watch'),
    simUnit: DeviceInfo.empty('SIM Unit Pro'),
  );

  bool get isAnyConnected => watch.isConnected || simUnit.isConnected;
  bool get areBothConnected => watch.isConnected && simUnit.isConnected;

  DeviceStatusModel copyWith({
    DeviceInfo? watch,
    DeviceInfo? simUnit,
  }) => DeviceStatusModel(
    watch:   watch   ?? this.watch,
    simUnit: simUnit ?? this.simUnit,
  );
}
