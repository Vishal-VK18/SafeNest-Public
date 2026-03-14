// lib/screens/home_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../utils/app_theme.dart';
import 'dashboard_tab.dart';
import 'journey_tab.dart';
import 'device_connection_screen.dart';
import 'emergency_alert_screen.dart';
import 'profile_screen.dart';
import 'alerts/event_history_screen.dart';
import '../models/safety_event_model.dart';
import '../widgets/safe_nest_bottom_navigation.dart';


class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  bool _sosVisible = false;

  @override
  Widget build(BuildContext context) {
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

    final _selectedTab = ref.watch(selectedTabProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedTab != 0) {
          ref.read(selectedTabProvider.notifier).state = 0;
        } else {
          // You could allow exit here if needed, but per requirements we maintain stable nav.
          // For now, we do nothing to keep them on dashboard as per "stable" hint.
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _selectedTab,
          children: [
            const DashboardTab(),
            JourneyTab(onSwitchTab: (i) => ref.read(selectedTabProvider.notifier).state = i),
            const DeviceConnectionScreen(),
            EventHistoryScreen(
              onBack: () => ref.read(selectedTabProvider.notifier).state = 0,
            ),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: const SafeNestBottomNavigation(),
      ),
    );
  }




  Future<void> _showSOSModal() async {
    if (_sosVisible) return;
    _sosVisible = true;

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
      pageBuilder: (context, _, __) => EmergencyAlertScreen(),
    );

    _sosVisible = false;
    ref.read(manualSOSProvider.notifier).state = false;
  }
}