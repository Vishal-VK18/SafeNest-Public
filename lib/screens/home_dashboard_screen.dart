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
import 'package:google_fonts/google_fonts.dart';

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
            // Floating pill nav bar
            Positioned(
              left: 0, right: 0, bottom: 16,
              child: _buildBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC09D).withOpacity(0.2), // shadow-peach/20
              blurRadius: 24, // shadow-2xl equivalent ish
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, Icons.grid_view_rounded, 'Dashboard'),
            _buildNavItem(1, Icons.auto_graph_rounded, 'Journey'),
            _buildNavItem(2, Icons.watch_rounded, 'Devices'),
            _buildNavItem(3, Icons.notifications_rounded, 'Alerts'),
            _buildNavItem(4, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        width: 64,
        height: 58,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF181818) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected ? const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : const Color(0xFFFFC09D),
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFFFFC09D),
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
