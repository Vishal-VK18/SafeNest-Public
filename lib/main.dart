// lib/main.dart
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
import 'screens/journey/appointment_details_screen.dart';
import 'screens/journey/hydration_tracker/hydration_tracker_screen.dart';
import 'screens/journey/sleep_oxygen_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        // ── Core flow ──────────────────────────────────────────────────────
        '/':               (context) => const SplashScreen(),
        '/login':          (context) => const LoginScreen(),
        '/create-account': (context) => const CreateAccountScreen(),
        '/home':           (context) => const HomeDashboardScreen(),
        '/home-wrapper':   (context) => const HomeWrapper(),

        // ── Main app sections ───────────────────────────────────────────────
        '/devices':    (context) => const DeviceConnectionScreen(),
        '/profile':    (context) => const ProfileScreen(),
        '/alerts':     (context) => const EmergencyAlertScreen(),

        // ── Journey sub-screens ─────────────────────────────────────────────
        '/appointment': (context) => const AppointmentDetailsScreen(),
        '/hydration':   (context) => const HydrationTrackerScreen(),
        '/sleep':       (context) => const SleepOxygenScreen(),
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
