// lib/screens/home_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../utils/app_theme.dart';
import '../widgets/vital_card.dart';
import 'device_connection_screen.dart';
import 'sim_module_status_screen.dart';
import 'emergency_alert_screen.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final health    = ref.watch(healthDataProvider);
    final pregnancy = ref.watch(pregnancyProvider);
    final fallActive = ref.watch(fallAlertActiveProvider);

    // Auto-navigate to emergency screen on fall detection
    ref.listen(fallAlertActiveProvider, (prev, next) {
      if (next && !(prev ?? false)) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EmergencyAlertScreen()),
        );
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
                _buildHomeTab(health, pregnancy, fallActive),
                _buildPregnancyTab(pregnancy),
                const DeviceConnectionScreen(),
                const SimModuleStatusScreen(),
              ],
            ),
            // Bottom nav
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _buildBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Home / Vitals tab ───────────────────────────────────────────────────────
  Widget _buildHomeTab(health, pregnancy, bool fallActive) {
    final syncLabel = health.receivedAt != null
        ? _timeAgo(health.receivedAt)
        : 'Never';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pregnancy.greeting},',
                    style: GoogleFonts.inter(
                      fontSize: 28, fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${pregnancy.userName}.',
                    style: GoogleFonts.inter(
                      fontSize: 28, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color:        Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border:       Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.statusGreen, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'You are safe right now.',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Avatar circle
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  pregnancy.userName.isNotEmpty ? pregnancy.userName[0] : 'U',
                  style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Fall alert banner ─────────────────────────────────────────────
          if (fallActive)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencyAlertScreen()),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:        AppColors.dangerRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border:       Border.all(color: AppColors.dangerRed.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'FALL DETECTED — Tap to respond',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, color: AppColors.dangerRed,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.dangerRed),
                  ],
                ),
              ),
            ),

          // ── Vital cards ───────────────────────────────────────────────────
          VitalCard(
            icon:        Icons.favorite,
            label:       'Heart Rate',
            value:       '${health.heartRate}',
            unit:        'BPM',
            statusLabel: health.heartRateStatus,
            isAlert:     !health.isHeartRateNormal && health.heartRate > 0,
          ),
          const SizedBox(height: 12),
          VitalCard(
            icon:        Icons.thermostat,
            label:       'Body Temp',
            value:       health.temperature.toStringAsFixed(1),
            unit:        '°C',
            statusLabel: health.temperatureStatus,
            isAlert:     !health.isTemperatureNormal && health.temperature > 0,
          ),
          const SizedBox(height: 12),
          VitalCard(
            icon:        Icons.shield,
            label:       'Fall Status',
            value:       health.fallStatus,
            statusLabel: health.fallDetected ? 'ALERT' : 'Normal',
            isAlert:     health.fallDetected,
          ),
          const SizedBox(height: 24),

          // ── Pregnancy quick summary ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF8C7FB2), AppColors.primary],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pregnancy.monthLabel.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: Colors.white70, letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      pregnancy.weekLabel,
                      style: GoogleFonts.inter(
                        fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white,
                      ),
                    ),
                    Text(
                      pregnancy.daysRemainingLabel,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Due Date',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white60),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pregnancy.estimatedDueDateLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Emergency button ──────────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmergencyAlertScreen()),
            ),
            icon:  const Icon(Icons.contact_support),
            label: const Text('Contact Care Provider'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Updated $syncLabel',
              style: GoogleFonts.inter(
                fontSize: 10, letterSpacing: 2,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Pregnancy Journey tab ───────────────────────────────────────────────────
  Widget _buildPregnancyTab(pregnancy) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  'Pregnancy Journey',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppColors.lavenderText,
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 24),
          // Circular progress
          SizedBox(
            width: 240, height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 240, height: 240,
                  child: CircularProgressIndicator(
                    value:            pregnancy.progressFraction,
                    strokeWidth:      14,
                    backgroundColor:  AppColors.softLilac,
                    valueColor:       AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                Container(
                  width: 190, height: 190,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:         Colors.black.withValues(alpha: 0.06),
                        blurRadius:    20,
                        offset:        const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pregnancy.monthLabel.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppColors.lavenderText.withValues(alpha: 0.5),
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        pregnancy.weekLabel,
                        style: GoogleFonts.inter(
                          fontSize: 32, fontWeight: FontWeight.w900,
                          color: AppColors.lavenderText,
                        ),
                      ),
                      Text(
                        pregnancy.daysRemainingLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.lavenderText.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              pregnancy.trimesterLabel.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: Colors.white, letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
          // Due date card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.softLilac),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.softLilac,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.calendar_today, color: AppColors.lavenderText),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTIMATED DUE DATE',
                        style: GoogleFonts.inter(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: AppColors.lavenderText.withValues(alpha: 0.4),
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        pregnancy.estimatedDueDateLabel,
                        style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppColors.lavenderText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.lavenderText.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom navigation ───────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final tabs = [
      (Icons.home_rounded,       Icons.home_outlined,          'HOME'),
      (Icons.auto_graph,         Icons.auto_graph,             'JOURNEY'),
      (Icons.watch_rounded,      Icons.watch_outlined,         'DEVICES'),
      (Icons.sim_card_rounded,   Icons.sim_card_outlined,      'SIM'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        border: const Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20, offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final selected = _selectedTab == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? tabs[i].$1 : tabs[i].$2,
                      color: selected ? AppColors.primary : Colors.grey[400],
                      size: 26,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tabs[i].$3,
                      style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: selected ? AppColors.primary : Colors.grey[400],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds} seconds ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    return DateFormat('HH:mm').format(dt);
  }
}
