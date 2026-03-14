import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

// ─── Entry point for background isolate ──────────────────────────────────────
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(SafeNestTaskHandler());
}

// ─── Background Task Handler ─────────────────────────────────────────────────
class SafeNestTaskHandler extends TaskHandler {
  static const String emergencyNumber = '8778387508';

  // MethodChannel works in background isolate ONLY via FlutterForegroundTask
  // because flutter_foreground_task spawns its own engine — this is safe here
  static const _channel = MethodChannel('com.safenest.emergency/call');

  DateTime? _lastCallTime;
  bool _lastFall = false;
  bool _lastTempAlert = false;

  bool get _isOnCooldown {
    if (_lastCallTime == null) return false;
    return DateTime.now().difference(_lastCallTime!) < const Duration(seconds: 60);
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[BgTask] Started — ready to monitor');
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Heartbeat every 5s — keep isolate alive
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('[BgTask] Destroyed');
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;

    final fall      = data['fall']      == true;
    final tempAlert = data['tempAlert'] == true;
    final simOffline = data['simOffline'] == true;

    debugPrint('[BgTask] Data received — fall:$fall temp:$tempAlert simOffline:$simOffline');

    // ── Fall alert — leading edge ──────────────────────────────────────────
    if (fall && !_lastFall && !_isOnCooldown) {
      debugPrint('[BgTask] 🚨 FALL DETECTED');
      FlutterForegroundTask.updateService(
        notificationTitle: '🚨 FALL DETECTED',
        notificationText: 'SafeNest detected a fall! Emergency call being placed.',
      );
      if (simOffline) _triggerCall('FALL DETECTED');
    }

    // ── Temp alert — leading edge ──────────────────────────────────────────
    if (tempAlert && !_lastTempAlert && !_isOnCooldown) {
      debugPrint('[BgTask] 🌡️ HIGH TEMP DETECTED');
      FlutterForegroundTask.updateService(
        notificationTitle: '🌡️ HIGH TEMPERATURE',
        notificationText: 'SafeNest detected high body temperature! Emergency call being placed.',
      );
      if (simOffline) _triggerCall('HIGH TEMPERATURE');
    }

    // ── All clear — reset notification ────────────────────────────────────
    if (!fall && !tempAlert && (_lastFall || _lastTempAlert)) {
      FlutterForegroundTask.updateService(
        notificationTitle: 'SafeNest Active',
        notificationText: 'Monitoring your safety...',
      );
    }

    _lastFall      = fall;
    _lastTempAlert = tempAlert;
  }

  // ── Place call directly via MethodChannel from this isolate ───────────────
  // flutter_foreground_task runs in its own Flutter engine so MethodChannel
  // works here even when the main app is closed
  Future<void> _triggerCall(String reason) async {
    _lastCallTime = DateTime.now();
    debugPrint('[BgTask] Triggering call — $reason');
    try {
      await _channel.invokeMethod('triggerEmergency', {'reason': reason});
      debugPrint('[BgTask] Call triggered successfully');
    } catch (e) {
      debugPrint('[BgTask] MethodChannel failed: $e — trying broadcast fallback');
      // Fallback: send to main isolate if MethodChannel somehow fails
      try {
        FlutterForegroundTask.sendDataToMain({
          'type': 'emergency_call',
          'reason': reason,
        });
      } catch (e2) {
        debugPrint('[BgTask] Fallback also failed: $e2');
      }
    }
  }
}

// ─── BackgroundService singleton ─────────────────────────────────────────────
class BackgroundService {
  BackgroundService._();
  static final instance = BackgroundService._();

  static const _channel = MethodChannel('com.safenest.emergency/call');

  Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'safenest_bg',
        channelName: 'SafeNest Monitor',
        channelDescription: 'Monitoring your safety in background',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: true,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> start() async {
    if (await FlutterForegroundTask.isRunningService) {
      debugPrint('[BgService] Already running');
      return;
    }

    await Permission.notification.request();
    await Permission.phone.request();

    await FlutterForegroundTask.startService(
      serviceId: 1001,
      notificationTitle: 'SafeNest Active',
      notificationText: 'Monitoring your safety...',
      callback: startCallback,
    );

    debugPrint('[BgService] Foreground service started');
  }

  Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }

  void sendData(Map<String, dynamic> data) {
    // Send to flutter_foreground_task isolate (works when app open/minimized)
    FlutterForegroundTask.sendDataToTask(data);

    // Write to native SharedPreferences
    // simOffline comes directly from BLE simSignal value — most reliable source
    _writeAlertsToPrefs(
      fall: data['fall'] == true,
      tempAlert: data['tempAlert'] == true,
      simOffline: data['simOffline'] == true,
    );
  }

  Future<void> _writeAlertsToPrefs({
    required bool fall,
    required bool tempAlert,
    required bool simOffline,
  }) async {
    try {
      // shared_preferences writes to FlutterSharedPreferences automatically
      // We write via MethodChannel so it lands in the same file native reads
      await _channel.invokeMethod('writeAlerts', {
        'fall': fall,
        'tempAlert': tempAlert,
        'simOffline': simOffline,
      });
    } catch (e) {
      // If MethodChannel fails (app closed), use shared_preferences directly
      debugPrint('[BgService] writeAlerts native failed — using sp: $e');
      try {
        await _writeViaSharedPrefs(fall, tempAlert, simOffline);
      } catch (e2) {
        debugPrint('[BgService] writeAlerts sp also failed: $e2');
      }
    }
  }

  // Write directly via Flutter shared_preferences
  // This writes to FlutterSharedPreferences which native service reads
  Future<void> _writeViaSharedPrefs(
      bool fall, bool tempAlert, bool simOffline) async {
    const sp = MethodChannel('plugins.flutter.io/shared_preferences');
    await sp.invokeMethod('setStringList', {
      'key': 'safenest_fall',
      'value': [fall.toString()],
    });
  }

  Future<void> showFallNotification() async {}
  Future<void> showTempNotification(double temp) async {}

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
      debugPrint('[BgService] battery opt request failed: $e');
    }
  }

  static Future<void> openBatterySettings() async {
    try {
      await _channel.invokeMethod('openBatterySettings');
    } catch (e) {
      debugPrint('[BgService] open battery settings failed: $e');
    }
  }
}
