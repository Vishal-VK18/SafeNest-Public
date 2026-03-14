import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class EmergencyCallService {
  EmergencyCallService._();
  static final instance = EmergencyCallService._();

  static const String emergencyNumber = '8778387508';
  // Note: Using the same channel as MainActivity.kt for battery/service
  static const _channel = MethodChannel('com.safenest.emergency/call');

  DateTime? _lastCallTime;
  static const _cooldown = Duration(seconds: 60);

  bool get _isOnCooldown {
    if (_lastCallTime == null) return false;
    return DateTime.now().difference(_lastCallTime!) < _cooldown;
  }

  Future<void> callIfNeeded({
    required bool simOffline,
    required String reason,
  }) async {
    if (!simOffline) {
      debugPrint('[EmergencyCall] SIM online — ESP handles call');
      return;
    }
    if (_isOnCooldown) {
      debugPrint('[EmergencyCall] On cooldown — skipping');
      return;
    }
    debugPrint('[EmergencyCall] Placing automatic call — $reason');
    await _makeCall();
  }

  Future<void> _makeCall() async {
    // Request CALL_PHONE permission
    final status = await Permission.phone.request();
    if (!status.isGranted) {
      debugPrint('[EmergencyCall] Permission denied');
      return;
    }

    try {
      _lastCallTime = DateTime.now();
      await _channel.invokeMethod('makeCall', {'number': emergencyNumber});
      debugPrint('[EmergencyCall] Call placed to $emergencyNumber');
    } catch (e) {
      debugPrint('[EmergencyCall] Call failed: $e');
    }
  }
}
