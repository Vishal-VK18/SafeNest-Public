// lib/screens/sim_module_status_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../utils/app_theme.dart';
import '../widgets/signal_bar.dart';
import '../widgets/battery_indicator.dart';

class SimModuleStatusScreen extends ConsumerWidget {
  const SimModuleStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health     = ref.watch(healthDataProvider);
    final devices    = ref.watch(deviceStatusProvider);
    final simConnected = devices.simUnit.isConnected;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SIM Module Status',
                    style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C1C1E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Main status card ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border:       Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Alive dot
                    Align(
                      alignment: Alignment.topRight,
                      child: _PingDot(active: simConnected),
                    ),
                    const SizedBox(height: 8),
                    // Icon
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.signal_cellular_alt,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      simConnected
                          ? 'SIM Safety Module Connected'
                          : 'SIM Safety Module Offline',
                      style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      simConnected
                          ? 'Direct cellular connection is active.'
                          : 'No cellular link. Ensure the SIM unit is powered on.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 20),
                    // Signal + Battery chips
                    Row(
                      children: [
                        Expanded(
                          child: _StatChip(
                            icon:  Icons.network_cell,
                            label: 'Signal',
                            child: SignalBar(level: health.simSignal),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatChip(
                            icon:  Icons.battery_charging_full,
                            label: 'Battery',
                            child: BatteryIndicator(percent: health.simBattery),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Warning banner (if not connected) ───────────────────────
              if (!simConnected)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:        AppColors.warningYellow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border:       Border.all(color: AppColors.warningYellow.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.warningYellow.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.error_outline, color: Colors.orange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SIM Module Not Detected',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, color: Colors.orange[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Alerts will be sent through the mobile app. Please ensure your phone is nearby.',
                              style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.orange[800]!.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // ── Connection Info list ─────────────────────────────────────
              Text(
                'CONNECTION INFO',
                style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: Colors.grey[400], letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:       Border.all(color: AppColors.primary.withValues(alpha: 0.07)),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon:  Icons.router,
                      label: 'Network Type',
                      value: health.networkType,
                      divider: true,
                    ),
                    _InfoRow(
                      icon:  Icons.settings_input_antenna,
                      label: 'GPS Status',
                      value: health.gpsLat != 0.0 ? 'Available' : 'Unavailable',
                      divider: true,
                    ),
                    _InfoRow(
                      icon:  Icons.location_on,
                      label: 'Last GPS Coords',
                      value: health.gpsString,
                      divider: true,
                    ),
                    _InfoRow(
                      icon:  Icons.sms,
                      label: 'Last SMS Alert',
                      value: health.lastSmsTime != null
                          ? DateFormat('MMM d, HH:mm').format(health.lastSmsTime!)
                          : 'None',
                      divider: true,
                    ),
                    _InfoRow(
                      icon:  Icons.update,
                      label: 'Last Sync',
                      value: _timeAgo(health.receivedAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Info banner ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:        AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'The SIM Module provides an independent connection for fall detection. This ensures emergency contacts are notified even if your smartphone is out of reach.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.grey[600], height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Action buttons ───────────────────────────────────────────
              ElevatedButton(
                onPressed: () => ref.read(deviceStatusProvider.notifier).reconnect(),
                style: ElevatedButton.styleFrom(
                  minimumSize:      const Size.fromHeight(54),
                  backgroundColor:  AppColors.primary,
                  foregroundColor:  Colors.white,
                  shape:            const StadiumBorder(),
                ),
                child: const Text('Refresh Connection'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  foregroundColor: AppColors.primary,
                  side:       BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                  shape:      const StadiumBorder(),
                ),
                child: const Text('Troubleshoot Connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds} sec ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return DateFormat('HH:mm').format(dt);
  }
}

// ─── Ping dot ──────────────────────────────────────────────────────────────
class _PingDot extends StatefulWidget {
  final bool active;
  const _PingDot({required this.active});

  @override
  State<_PingDot> createState() => _PingDotState();
}

class _PingDotState extends State<_PingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? AppColors.statusGreen : Colors.grey;

    return SizedBox(
      width: 20, height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.active)
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Container(
                width: 16 + _ctrl.value * 8,
                height: 16 + _ctrl.value * 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.4 * (1 - _ctrl.value)),
                ),
              ),
            ),
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  final bool     divider;
  const _InfoRow({required this.icon, required this.label, required this.value, this.divider = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary.withValues(alpha: 0.6), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        if (divider)
          Container(height: 1, color: AppColors.bgLight),
      ],
    );
  }
}

// ─── Stat chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Widget   child;
  const _StatChip({required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w700,
              color: Colors.grey[500], letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
