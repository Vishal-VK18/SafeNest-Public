import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BackgroundService {
  BackgroundService._();

  static const _channel = MethodChannel('com.safenest.safenest/ble_monitor');

  static void init() {}

  static Future<void> start() async {
    try {
      await _channel.invokeMethod('startService');
      debugPrint('[BackgroundService] Native service started');
    } catch (e) {
      debugPrint('[BackgroundService] start failed: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopService');
    } catch (e) {
      debugPrint('[BackgroundService] stop failed: $e');
    }
  }

  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      return await _channel.invokeMethod('isIgnoringBatteryOptimizations') ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      debugPrint('[BackgroundService] battery optimization request failed: $e');
    }
  }

  static Future<void> openBatterySettings() async {
    try {
      await _channel.invokeMethod('openBatterySettings');
    } catch (e) {
      debugPrint('[BackgroundService] open battery settings failed: $e');
    }
  }

  static Future<void> showFallNotification() async {}
  static Future<void> showTempNotification(double temp) async {}
}
