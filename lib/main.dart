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
import 'screens/home_dashboard_screen.dart';
import 'screens/device_connection_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/emergency_alert_screen.dart';
import 'screens/safety_event_history_screen.dart';

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
      initialRoute: '/',
      routes: {
        '/':        (context) => const SplashScreen(),
        '/home':    (context) => const HomeDashboardScreen(),
        '/devices': (context) => const DeviceConnectionScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/history': (context) => SafetyEventHistoryScreen(),
        '/alerts':  (context) => const EmergencyAlertScreen(),
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
