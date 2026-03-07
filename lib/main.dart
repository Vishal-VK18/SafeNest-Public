import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/ble_service.dart';
import 'services/background_service.dart';
import 'services/system_service.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/get_started_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/create_account_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/device_connection_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/emergency_alert_screen.dart';
import 'core/constants/route_constants.dart';
import 'core/navigation/page_transitions.dart';
import 'screens/alerts/alerts_screen.dart';
import 'screens/logs/heart_rate_log_screen.dart';
import 'screens/logs/temperature_log_page.dart';
import 'screens/logs/fall_event_log_screen.dart';
import 'screens/logs/heart_rate_page.dart';
import 'screens/logs/temperature_page.dart';
import 'screens/sim_module_status_screen.dart';
import 'screens/journey/hydration_tracker/hydration_tracker_screen.dart';
import 'screens/journey/sleep_oxygen_screen.dart';
import 'screens/journey/appointment_details_screen.dart';

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
    } catch (e) {
      debugPrint('SafeNest: StorageService.init() failed: $e');
    }

    // Init foreground task communication port before runApp
    FlutterForegroundTask.initCommunicationPort();

    // Init background service config before runApp
    BackgroundService.init();

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

  // 4. Start native background service
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      await BackgroundService.start();
    } else {
      debugPrint('SafeNest: BackgroundService skipped on desktop platform.');
    }
  } catch (e) {
    debugPrint('SafeNest: BackgroundService.start() failed: $e');
  }

  // 5. Battery optimization — ask only once ever
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
        RouteConstants.getStarted: (context) => const GetStartedScreen(),
        RouteConstants.login: (context) => const LoginScreen(),
        RouteConstants.createAccount: (context) => const CreateAccountScreen(),
        RouteConstants.home:    (context) => const HomeDashboardScreen(),
        RouteConstants.dashboard: (context) => const HomeDashboardScreen(),
        RouteConstants.journey:  (context) => const HomeDashboardScreen(),
        RouteConstants.devices: (context) => const DeviceConnectionScreen(),
        RouteConstants.profile: (context) => const SettingsScreen(),
        RouteConstants.alerts:  (context) => const EmergencyAlertScreen(),
        RouteConstants.alertsList: (context) => const AlertsScreen(),
        RouteConstants.hydration:          (context) => const HydrationTrackerScreen(initialPage: 0),
        RouteConstants.hydrationStats:     (context) => const HydrationTrackerScreen(initialPage: 1),
        RouteConstants.hydrationReminders: (context) => const HydrationTrackerScreen(initialPage: 2),
        RouteConstants.sleep:              (context) => const SleepOxygenScreen(),
        RouteConstants.appointment:        (context) => const AppointmentDetailsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == RouteConstants.heartRate) {
          return PageTransitions.slideRightToLeft(const HeartRatePage());
        }
        if (settings.name == RouteConstants.temperature) {
          return PageTransitions.slideRightToLeft(const TemperaturePage());
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
