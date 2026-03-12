import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../models/device_status_model.dart';
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
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
                      Expanded(child: _buildSleepCard(context)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildHydrationCard(context)),
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
      ),
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
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
                    image: const DecorationImage(
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
      onTap: () => Navigator.pushNamed(context, RouteConstants.heartRate),
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
      onTap: () => Navigator.pushNamed(context, RouteConstants.temperature),
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
              ],
            ),
            const Icon(Icons.device_thermostat, color: Color(0xFFA68E86), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard(BuildContext context) {
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
                  decoration: BoxDecoration(color: const Color(0xFF79B39B).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                  child: Text('GOOD', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF79B39B))),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('SLEEP TRACKER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: const Color(0xFFA68E86))),
            const SizedBox(height: 2),
            Text('6h 45m', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2D2D2D))),
            const SizedBox(height: 4),
            Text('Last night sleep', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA68E86))),
          ],
        ),
      ),
    );
  }

  Widget _buildHydrationCard(BuildContext context) {
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
                Row(
                  children: [
                    Container(width: 4, height: 12, decoration: BoxDecoration(color: const Color(0xFFE68C6C).withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 2),
                    Container(width: 4, height: 12, decoration: BoxDecoration(color: const Color(0xFFE68C6C), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 2),
                    Container(width: 4, height: 12, decoration: BoxDecoration(color: const Color(0xFFE68C6C).withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
                  ],
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
                Text('3/8', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2D2D2D))),
                const SizedBox(width: 4),
                Text('cups', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF2D2D2D).withOpacity(0.6))),
              ],
            ),
            const SizedBox(height: 4),
            Text('Water intake', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFA68E86))),
          ],
        ),
      ),
    );
  }

  Widget _buildFallDetectionCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VitalsScreen(initialTab: 2))),
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
            const SizedBox(height: 24),
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
        MaterialPageRoute(builder: (context) => const AppointmentDetailsScreen()),
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
      color: Colors.white.withOpacity(0.75),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withOpacity(0.4)),
      boxShadow: const [
        BoxShadow(color: Color(0x26BAA59F), blurRadius: 32, offset: Offset(0, 8)),
      ],
    );
  }
}
