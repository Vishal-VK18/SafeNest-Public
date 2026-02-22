// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/ble_service.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';

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

  // Start BLE service (mock mode by default; set useMockData = false for hardware)
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
      title:            'SafeNest',
      debugShowCheckedModeBanner: false,
      theme:            AppTheme.light,
      home:             const SplashScreen(),
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
