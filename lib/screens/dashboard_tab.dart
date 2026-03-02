// lib/screens/dashboard_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/device_status_model.dart';
import '../utils/app_theme.dart';
import '../core/constants/route_constants.dart';
import '../widgets/interactive_card_wrapper.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health      = ref.watch(healthDataProvider);
    final pregnancy   = ref.watch(pregnancyProvider);
    final deviceState = ref.watch(deviceStatusProvider);
    
    final isConnected = deviceState.watch.status == ConnectionStatus.connected;
    final hasData     = health.receivedAt.year > 2000; // Received real packet

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pregnancy.greeting},',
                    style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
                  ),
                  Text(
                    pregnancy.userName,
                    style: GoogleFonts.inter(
                      fontSize: 28, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C1C1E),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, RouteConstants.profile),
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      color: AppColors.primary.withOpacity(0.1),
                      child: Center(
                        child: Text(
                          pregnancy.userName.isNotEmpty ? pregnancy.userName[0] : 'U',
                          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Safety Banner ──────────────────────────────────────────────────
          _buildSafetyBanner(isConnected, health.fallDetected),
          
          const SizedBox(height: 40),

          // ── Vitals Section ───────────────────────────────────────────────
          InteractiveCardWrapper(
            onTap: () => Navigator.pushNamed(context, RouteConstants.heartRate),
            child: _buildVitalCard(
              icon: Icons.favorite,
              label: 'Heart Rate',
              value: isConnected && hasData ? '${health.heartRate}' : '--',
              unit: 'BPM',
              status: isConnected && hasData ? (health.isHeartRateNormal ? 'Normal' : 'Alert') : 'Waiting',
              isNormal: health.isHeartRateNormal || !hasData,
            ),
          ),
          const SizedBox(height: 16),
          InteractiveCardWrapper(
            onTap: () => Navigator.pushNamed(context, RouteConstants.temperature),
            child: _buildVitalCard(
              icon: Icons.thermostat,
              label: 'Body Temp',
              value: isConnected && hasData ? health.temperature.toStringAsFixed(1) : '--',
              unit: '°C',
              status: isConnected && hasData ? (health.isTemperatureNormal ? 'Normal' : 'Alert') : 'Waiting',
              isNormal: health.isTemperatureNormal || !hasData,
            ),
          ),
          const SizedBox(height: 16),
          InteractiveCardWrapper(
            onTap: () => Navigator.pushNamed(context, RouteConstants.fallEventLog),
            child: _buildVitalCard(
              icon: Icons.shield,
              label: 'Fall Status',
              value: health.fallDetected ? 'Fall Detected' : 'No Issues',
              unit: '',
              status: health.fallDetected ? 'Alert' : 'Normal',
              isNormal: !health.fallDetected,
            ),
          ),

          const SizedBox(height: 40),

          // ── Weekly Summary ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Activity', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () {}, child: const Text('View Trends')),
            ],
          ),
          const SizedBox(height: 12),
          _buildActivityChart(),

          const SizedBox(height: 32),
          
          // ── Emergency Button ──────────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, RouteConstants.alerts),
            icon: const Icon(Icons.contact_support),
            label: const Text('Contact Care Provider'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 4,
              shadowColor: AppColors.primary.withOpacity(0.25),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              isConnected ? 'Updated ${_timeAgo(health.receivedAt)}' : 'Disconnected',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400], letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyBanner(bool connected, bool fall) {
    Color bgColor = AppColors.statusGreen.withOpacity(0.1);
    Color txt = AppColors.statusGreen;
    String label = "You are safe right now.";
    IconData icon = Icons.check_circle;

    if (!connected) {
      bgColor = Colors.grey.withOpacity(0.1);
      txt = Colors.grey;
      label = "Waiting for device connection...";
      icon = Icons.watch_later;
    } else if (fall) {
      bgColor = AppColors.dangerRed.withOpacity(0.1);
      txt = AppColors.dangerRed;
      label = "Fall detected! Sending alert.";
      icon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: txt, size: 20),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildVitalCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required String status,
    required bool isNormal,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text(unit, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (isNormal ? AppColors.statusGreen : AppColors.dangerRed).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (isNormal ? AppColors.statusGreen : AppColors.dangerRed).withOpacity(0.2)),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isNormal ? AppColors.statusGreen : AppColors.dangerRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    final heights = [0.6, 0.45, 0.75, 0.5, 0.9, 0.3, 0.85];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            height: 160,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) => Container(
                width: 32,
                height: 160 * heights[i],
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(i == 4 ? 0.8 : 0.4),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              )),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('M', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('T', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('W', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('T', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('F', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('S', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('S', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 10) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return DateFormat('HH:mm').format(dt);
  }
}
