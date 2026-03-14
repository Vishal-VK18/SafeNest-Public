import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/ble_service.dart';
import 'services/background_service.dart';
import 'models/device_status_model.dart';
import 'services/system_service.dart';
import 'services/firebase_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'core/providers/logs_provider.dart';
import 'core/models/log_parameter.dart';
import 'screens/logs/logs_detail_screen.dart';

import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/get_started_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/create_account_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/device_connection_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/emergency_alert_screen.dart';
import 'screens/sos_sent_screen.dart';
import 'core/constants/route_constants.dart';
import 'core/navigation/page_transitions.dart';
import 'screens/alerts/alerts_screen.dart';
import 'screens/logs/heart_rate_log_screen.dart';
import 'screens/logs/temperature_log_page.dart';
import 'screens/logs/fall_event_log_screen.dart';

import 'screens/sim_module_status_screen.dart';
import 'screens/journey/hydration_tracker/hydration_tracker_screen.dart';
import 'screens/journey/sleep_tracker_screen.dart';
import 'screens/journey/appointment_details_screen.dart';
import 'screens/vitals/vitals_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM background message: ${message.messageId}');
}

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
    };

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    try {
      await StorageService.init();
      // Open auth prefs box early so splash can read it fast
      await Hive.openBox('auth_prefs');
    } catch (e) {
      debugPrint('SafeNest: StorageService.init() failed: $e');
    }

    // Firebase initialization
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // CRITICAL: Enable offline persistence BEFORE any database read/write
      // Must use instanceFor with explicit databaseURL for asia-southeast1 region
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://safenest-5bbc2-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).setPersistenceEnabled(true);

      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://safenest-5bbc2-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).setPersistenceCacheSizeBytes(10485760); // 10MB offline cache
      
      debugPrint('SafeNest: Firebase & RTDB initialized');
    } catch (e) {
      debugPrint('SafeNest: Firebase init failed: $e');
    }


    // FCM background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Init foreground task communication port before runApp
    FlutterForegroundTask.initCommunicationPort();

    // Fallback — if background MethodChannel fails, main isolate handles it
    FlutterForegroundTask.addTaskDataCallback((data) {
      if (data is Map && data['type'] == 'emergency_call') {
        final reason = data['reason'] ?? 'Alert';
        debugPrint('[Main] Emergency fallback call from bg: $reason');
        const channel = MethodChannel('com.safenest.emergency/call');
        channel.invokeMethod('triggerEmergency', {'reason': reason});
      }
    });

    // Init background service config before runApp
    BackgroundService.instance.init();

    runApp(
      const ProviderScope(
        child: WithForegroundTask(child: SafeNestApp()),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServicesAsync();
    });
  }, (error, stack) {
    debugPrint('SafeNest Global Error: $error');
    debugPrint(stack.toString());
  });
}

Future<void> _initServicesAsync() async {
  // 1. Notifications
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('SafeNest: NotificationService.init() failed: $e');
  }

  // 2. Permissions
  try {
    await SystemService.instance.requestPermissions();
  } catch (e) {
    debugPrint('SafeNest: requestPermissions() failed: $e');
  }

  // 3. BLE
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      await BleService.instance.start();
    } else {
      debugPrint('SafeNest: BLE skipped on desktop platform.');
    }
  } catch (e) {
    debugPrint('SafeNest: BleService.start() failed: $e');
  }

  // 4. Start background monitoring service
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      await BackgroundService.instance.start();

      // Start native watchdog service — survives app being swiped away
      try {
        const channel = MethodChannel('com.safenest.emergency/call');
        await channel.invokeMethod('writeAlerts', {
          'fall': false,
          'tempAlert': false,
          'simOffline': false,
        });
        // Start the watchdog service via Android
        debugPrint('SafeNest: Native watchdog initialized');
      } catch (e) {
        debugPrint('SafeNest: Watchdog init failed: $e');
      }

      // Forward BLE health data to background isolate AND native watchdog
      BleService.instance.healthStream.listen((health) {
        // Derive SIM status directly from BLE packet — most reliable
        // simSignal = 0 means SIM module is off/offline
        // simSignal > 0 means SIM module is on and has network
        final simOffline = health.simSignal == 0;

        final data = {
          'fall': health.fallDetected,
          'tempAlert': health.tempAlert == 1,
          'simOffline': simOffline,
        };

        // 1. Send to flutter_foreground_task isolate
        BackgroundService.instance.sendData(data);

        // 2. Write to shared_preferences — simOffline based on simSignal from BLE packet
        // Use health.simSignal directly — no dependency on deviceStatus
        // simSignal = 0 means SIM is offline, > 0 means SIM is online
        _writeAlertsToSharedPrefs(
          fall: health.fallDetected,
          tempAlert: health.tempAlert == 1,
          simOffline: health.simSignal == 0,
        );
      });
    } else {
      debugPrint('SafeNest: BackgroundService skipped on desktop platform.');
    }
  } catch (e) {
    debugPrint('SafeNest: BackgroundService.start() failed: $e');
  }

  // 5. Firebase FCM
  try {
    await FirebaseService.instance.initFCM();
  } catch (e) {
    debugPrint('SafeNest: FCM init failed: $e');
  }

  // 6. Battery optimization — ask only once ever
  try {
    final alreadyAsked = StorageService.getBatteryPermissionAsked();
    if (!alreadyAsked) {
      final ignoring = await BackgroundService.isIgnoringBatteryOptimizations();
      if (!ignoring) {
        await BackgroundService.requestIgnoreBatteryOptimizations();
        await Future.delayed(const Duration(seconds: 2));
        await BackgroundService.openBatterySettings();
      }
      await StorageService.setBatteryPermissionAsked(true);
    }
  } catch (e) {
    debugPrint('SafeNest: Battery optimization failed: $e');
  }
}

Future<void> _writeAlertsToSharedPrefs({
  required bool fall,
  required bool tempAlert,
  required bool simOffline,
}) async {
  try {
    const channel = MethodChannel('com.safenest.emergency/call');
    await channel.invokeMethod('writeAlerts', {
      'fall': fall,
      'tempAlert': tempAlert,
      'simOffline': simOffline,
    });
  } catch (e) {
    debugPrint('[Main] writeAlerts failed: $e');
  }
}


class SafeNestApp extends StatelessWidget {
  const SafeNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: RouteConstants.splash,
      routes: {
        '/': (context) => const SplashScreen(),
        RouteConstants.splash: (context) => const SplashScreen(),
        RouteConstants.getStarted: (context) => const OnboardingScreen(),
        RouteConstants.login: (context) => const LoginScreen(),
        RouteConstants.createAccount: (context) => const CreateAccountScreen(),
        RouteConstants.home:    (context) => HomeDashboardScreen(),
        RouteConstants.dashboard: (context) => HomeDashboardScreen(),
        RouteConstants.journey:  (context) => HomeDashboardScreen(),
        RouteConstants.devices: (context) => const DeviceConnectionScreen(),
        RouteConstants.profile: (context) => const SettingsScreen(),
        RouteConstants.alerts:  (context) => const EmergencyAlertScreen(),
        RouteConstants.alertsList: (context) => const AlertsScreen(),
        RouteConstants.hydration:          (context) => const HydrationTrackerScreen(initialPage: 0),
        RouteConstants.hydrationStats:     (context) => const HydrationTrackerScreen(initialPage: 1),
        RouteConstants.hydrationReminders: (context) => const HydrationTrackerScreen(initialPage: 2),
        RouteConstants.sleep:              (context) => const SleepTrackerScreen(),
        RouteConstants.appointment:        (context) => const AppointmentDetailsScreen(),
        RouteConstants.sosSent:            (context) => const SosSentScreen(),
        RouteConstants.logsDetail: (context) {
          final parameter = ModalRoute.of(context)!.settings.arguments as LogParameter;
          return LogsDetailScreen(parameter: parameter);
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == RouteConstants.vitals) {
          int initialTab = 0;
          if (settings.arguments is Map<String, dynamic>) {
            final args = settings.arguments as Map<String, dynamic>;
            initialTab = args['initialTab'] ?? 0;
          }
          return PageTransitions.slideRightToLeft(VitalsScreen(initialTab: initialTab));
        }
        if (settings.name == RouteConstants.heartRate) {
          return PageTransitions.slideRightToLeft(const VitalsScreen(initialTab: 0));
        }
        if (settings.name == RouteConstants.temperature) {
          return PageTransitions.slideRightToLeft(const VitalsScreen(initialTab: 1));
        }
        if (settings.name == RouteConstants.heartRateLog) {
          return PageTransitions.slideRightToLeft(const HeartRateLogScreen());
        }
        if (settings.name == RouteConstants.temperatureLog) {
          return PageTransitions.slideRightToLeft(const TemperatureLogPage());
        }
        if (settings.name == RouteConstants.fallEventLog) {
          return PageTransitions.slideRightToLeft(const FallEventLogScreen());
        }
        if (settings.name == RouteConstants.simStatus) {
          return PageTransitions.slideRightToLeft(const SIMModuleStatusScreen());
        }
        return null;
      },
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
          ),
          child: child!,
        );
      },
    );
  }
}
