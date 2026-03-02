import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/ble_service.dart';
import 'services/system_service.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/create_account_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/device_connection_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/home_wrapper.dart';
import 'screens/emergency_alert_screen.dart';
import 'core/constants/route_constants.dart';
import 'core/navigation/page_transitions.dart';
import 'screens/logs/heart_rate_log_screen.dart';
import 'screens/logs/temperature_log_page.dart';
import 'screens/logs/fall_event_log_screen.dart';
import 'screens/logs/heart_rate_page.dart';
import 'screens/logs/temperature_page.dart';
import 'screens/sim_module_status_screen.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
    };

    // Force portrait mode
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Initialize local storage (Hive)
    await StorageService.init();

    // Initialize notifications
    await NotificationService.init();

    // Startup Permissions
    await SystemService.instance.requestPermissions();

    // Start BLE service
    await BleService.instance.start();

    runApp(
      const ProviderScope(child: SafeNestApp()),
    );
  }, (error, stack) {
    debugPrint('SafeNest Global Error: $error');
    debugPrint(stack.toString());
  });
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
        RouteConstants.splash: (context) => const SplashScreen(),
        RouteConstants.home:    (context) => const HomeDashboardScreen(),
        RouteConstants.devices: (context) => const DeviceConnectionScreen(),
        RouteConstants.profile: (context) => const ProfileScreen(),
        RouteConstants.alerts:  (context) => const EmergencyAlertScreen(),
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
      // Ensure iOS status bar styling
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
