import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../core/models/log_parameter.dart';

import '../models/device_status_model.dart';
import '../models/sleep_tracker_model.dart';
import '../core/constants/route_constants.dart';
import 'profile_screen.dart';
import 'journey/appointment_details_screen.dart';
import 'vitals/vitals_screen.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthDataProvider);
    final pregnancy = ref.watch(pregnancyProvider);
    final deviceState = ref.watch(deviceStatusProvider);

    final isConnected = deviceState.watch.status == ConnectionStatus.connected;
    final hasData = health.receivedAt.year > 2000;

    return Stack(
      children: [
        // Background Gradient
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)],
              ),
            ),
          ),
        ),
        // Radial diffusion overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.4),
                radius: 1.0,
                colors: [
                  Colors.white.withOpacity(0.5),
                  Colors.white.withOpacity(0.2),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
        
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, pregnancy),
                const SizedBox(height: 16),
                _buildHeartRateCard(context, isConnected, hasData, health),
                const SizedBox(height: 16),
                _buildBodyTempCard(context, isConnected, hasData, health),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildSleepCard(context, ref)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildHydrationCard(context, ref)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFallDetectionCard(context),
                const SizedBox(height: 16),
                _buildUpcomingAppointmentCard(context, ref),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, dynamic pregnancy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                    image: pregnancy.photoLocalPath != null
                        ? DecorationImage(
                            image: FileImage(File(pregnancy.photoLocalPath!)),
                            fit: BoxFit.cover,
                          )
                        : const DecorationImage(
                            image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDxUahFZlLNPAFNq6UMAo6AhmVyEcbrAw9JrWGNMU0Zj1QWPwC_-dtX6XKTzfePUG6v4ut9P4ww6C2pkRR-tK0ACDfpzRaP-yTdCPqbJzJ7OR0_yGJaISJWceJKVcEGPVnFG-vt3aQRzsBvHEL-P43TS2N5veQ4V_l3XJlhtbiTSvqYfdm6t5x0-vFhMOFzkl-UoxPaj3vOQmA0R4vP3LEk2SeK4HIeGKNzVy3dofWxTJI199OsVZbH3aFtAdZYCYyQqVGrcq0JPiIP'),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pregnancy.userName.isNotEmpty ? pregnancy.userName : 'Sarah'}, ${pregnancy.age ?? 27}',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2D2D2D), height: 1.1),
                    ),
                    Text(
                      'Week ${pregnancy.pregnancyWeek} Pregnancy',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFFA68E86)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, RouteConstants.alertsList),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded, color: Color(0xFF2D2D2D), size: 20),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE68C6C),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateCard(BuildContext context, bool isConnected, bool hasData, dynamic health) {
    return GestureDetector(
      onTap: () {
        debugPrint('[SafeNest Nav] Dashboard -> Heart Rate tab');
        Navigator.pushNamed(
          context,
          RouteConstants.vitals,
          arguments: {'initialTab': 0},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: _blushCardDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HEART RATE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFFE68C6C).withOpacity(0.8))),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      isConnected && hasData ? '${health.heartRate}' : '--',
                      style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w800, color: const Color(0xFF2D2D2D), letterSpacing: -1),
                    ),
                    const SizedBox(width: 4),
                    Text('BPM', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2D2D2D).withOpacity(0.6))),
                  ],
                ),
                Text('Current Heart Rate', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA68E86))),
              ],
            ),
            const Icon(Icons.favorite, color: Color(0xFFE68C6C), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyTempCard(BuildContext context, bool isConnected, bool hasData, dynamic health) {
    return GestureDetector(
      onTap: () {
        debugPrint('[SafeNest Nav] Dashboard -> Temperature tab');
        Navigator.pushNamed(
          context,
          RouteConstants.vitals,
          arguments: {'initialTab': 1},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: _blushCardDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BODY TEMPERATURE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFFA68E86))),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      isConnected && hasData ? health.temperature.toStringAsFixed(1) : '--.-',
                      style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w800, color: const Color(0xFF2D2D2D), letterSpacing: -1),
                    ),
                    const SizedBox(width: 4),
                    Text('°C', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2D2D2D).withOpacity(0.6))),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
            const Icon(Icons.device_thermostat, color: Color(0xFFA68E86), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard(BuildContext context, WidgetRef ref) {
    final sleepState = ref.watch(sleepTrackerProvider);
    final lastSession = sleepState.lastSession;
    final isTracking = sleepState.isTracking;

    String sleepLabel;
    String sleepSub;
    String statusTag;
    Color tagColor;

    if (isTracking) {
      sleepLabel = ref.read(sleepTrackerProvider.notifier).formattedElapsed;
      sleepSub   = 'Tracking now…';
      statusTag  = 'ACTIVE';
      tagColor   = const Color(0xFFE68C6C);
    } else if (lastSession != null) {
      sleepLabel = lastSession.formattedDuration;
      sleepSub   = 'Last session duration';
      statusTag  = lastSession.qualityFromDuration.toUpperCase();
      tagColor   = const Color(0xFF79B39B);
    } else {
      sleepLabel = '--';
      sleepSub   = 'No sleep data';
      statusTag  = 'READY';
      tagColor   = const Color(0xFFE9A48E);
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RouteConstants.sleep),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _blushCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFE68C6C).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.nights_stay, color: Color(0xFFE68C6C), size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: tagColor.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                  child: Text(statusTag, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: tagColor)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('SLEEP TRACKER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: const Color(0xFFA68E86))),
            const SizedBox(height: 2),
            Text(sleepLabel, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2D2D2D))),
            const SizedBox(height: 4),
            Text(sleepSub, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA68E86))),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, RouteConstants.logsDetail, arguments: LogParameter.sleep),
              child: Text('View Full Logs →', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFE9A48E))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHydrationCard(BuildContext context, WidgetRef ref) {
    final hydration = ref.watch(hydrationProvider);
    // 250ml per cup
    final cups = (hydration.intakeLiters / 0.25).round();
    const goalCups = 8;
    final pct = (hydration.intakeLiters / 2.0).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RouteConstants.hydration),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _blushCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF6FA8DC).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.water_drop_outlined, color: Color(0xFF6FA8DC), size: 20),
                ),
                // mini bar
                Row(
                  children: List.generate(3, (i) {
                    final filled = (pct * 3) > i;
                    return Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Container(
                        width: 4, height: 12,
                        decoration: BoxDecoration(
                          color: filled ? const Color(0xFFE68C6C) : const Color(0xFFE68C6C).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('HYDRATION', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: const Color(0xFFA68E86))),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$cups/$goalCups', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2D2D2D))),
                const SizedBox(width: 4),
                Text('cups', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF2D2D2D).withOpacity(0.6))),
              ],
            ),
            const SizedBox(height: 4),
            Text('Water intake today', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA68E86))),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, RouteConstants.logsDetail, arguments: LogParameter.hydration),
              child: Text('View Logs →', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFE9A48E))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallDetectionCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        debugPrint('[SafeNest Nav] Dashboard -> Fall Detection tab');
        Navigator.pushNamed(
          context,
          RouteConstants.vitals,
          arguments: {'initialTab': 2},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: _blushCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF3DBB7C), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('Fall Detection Operational', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2D2D2D))),
                  ],
                ),
                const Icon(Icons.shield_outlined, color: Color(0xFFA68E86), size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text('All systems operational. No falls detected this week.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA68E86))),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, RouteConstants.logsDetail, arguments: LogParameter.fallDetection),
              child: Text('View Detection History →', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFE9A48E))),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildActivityBar('M', false),
                _buildActivityBar('T', false),
                _buildActivityBar('W', false),
                _buildActivityBar('T', true),
                _buildActivityBar('F', false),
                _buildActivityBar('S', false),
                _buildActivityBar('S', false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityBar(String label, bool isToday) {
    return Column(
      children: [
        Container(
          width: 6,
          height: 48,
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFF8FD1B4) : const Color(0xFFE6DAD5),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFA68E86))),
      ],
    );
  }

  Widget _buildUpcomingAppointmentCard(BuildContext context, WidgetRef ref) {
    final nextAppt = ref.watch(nextUpcomingAppointmentProvider);
    if (nextAppt == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AppointmentDetailsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: _blushCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: const Color(0xFFFFC09D).withOpacity(0.15), borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.event_note, color: Color(0xFFFFC09D), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Next Checkup', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFA68E86))),
                  const SizedBox(height: 4),
                  Text(nextAppt.doctorName, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D2D2D))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFA68E86), size: 20),
          ],
        ),
      ),
    );
  }

  BoxDecoration _blushCardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFFFF8F5), // Cream Background
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05), // rgba(0,0,0,0.05)
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
