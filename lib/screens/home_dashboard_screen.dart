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
import 'safety_event_history_screen.dart';
import '../models/safety_event_model.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  int _selectedTab = 0;
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
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _buildBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    const tabs = [
      (Icons.grid_view_rounded,  Icons.grid_view_outlined,   'DASHBOARD'),
      (Icons.auto_graph_rounded, Icons.auto_graph_outlined,  'JOURNEY'),
      (Icons.watch_rounded,      Icons.watch_outlined,       'DEVICES'),
      (Icons.history_rounded,    Icons.history_outlined,     'HISTORY'),
      (Icons.person_rounded,     Icons.person_outline,       'PROFILE'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: const Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20, offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final selected = _selectedTab == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? tabs[i].$1 : tabs[i].$2,
                        color: selected ? AppColors.primaryDark : Colors.grey[400],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tabs[i].$3,
                        style: GoogleFonts.inter(
                          fontSize: 8, fontWeight: FontWeight.w700,
                          color: selected ? AppColors.primaryDark : Colors.grey[400],
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
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
}
