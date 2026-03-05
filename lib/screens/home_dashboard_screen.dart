// lib/screens/home_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../utils/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import 'dashboard_tab.dart';
import 'journey_tab.dart';
import 'device_connection_screen.dart';
import 'emergency_alert_screen.dart';
import 'profile_screen.dart';
import 'safety_event_history_screen.dart';
import '../models/safety_event_model.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  int _selectedTab = 0;
  bool _sosVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestBackgroundPermissions(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Auto-show SOS modal on fall detection or manual trigger
    ref.listen(fallAlertActiveProvider, (prev, next) {
      if (next == true && prev != true) {
        _showSOSModal();
      }
    });

    ref.listen(manualSOSProvider, (prev, next) {
      if (next == true && prev != true) {
        _showSOSModal();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: _selectedTab,
              children: [
                const DashboardTab(),
                JourneyTab(onSwitchTab: (i) => setState(() => _selectedTab = i)),
                const DeviceConnectionScreen(),
                SafetyEventHistoryScreen(),
                const ProfileScreen(),
              ],
            ),
            // Animated bottom navigation bar
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: SafeNestBottomNavBar(
                selectedIndex: _selectedTab,
                onTabChange: (index, label) {
                  setState(() => _selectedTab = index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSOSModal() async {
    if (_sosVisible) return;
    _sosVisible = true;

    // Record the event
    final health = ref.read(healthDataProvider);
    final history = ref.read(safetyHistoryProvider.notifier);
    await history.recordFromHealth(
      health, 
      ref.read(manualSOSProvider) ? SafetyEventType.sos : SafetyEventType.fall,
    );

    if (!mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, _, __) => const EmergencyAlertScreen(),
    );

    _sosVisible = false;
    ref.read(manualSOSProvider.notifier).state = false;
  }

  Future<void> _requestBackgroundPermissions(BuildContext context) async {
    // Show dialog explaining why background permission needed
    final granted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Background Monitoring'),
        content: const Text(
          'SafeNest needs to run in the background to monitor your health and send alerts even when the app is closed.\n\nPlease allow SafeNest to run in the background on the next screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    if (granted == true) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }
}
