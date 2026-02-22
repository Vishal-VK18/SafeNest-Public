// lib/screens/device_connection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../models/device_status_model.dart';
import '../utils/app_theme.dart';
import '../widgets/connection_status_badge.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/signal_bar.dart';

class DeviceConnectionScreen extends ConsumerWidget {
  const DeviceConnectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceStatus = ref.watch(deviceStatusProvider);
    final health       = ref.watch(healthDataProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Background decorative blobs
            Positioned(
              top: MediaQuery.of(context).size.height * 0.22,
              right: -80,
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  color: AppColors.softLilac.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.28,
              left: -80,
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  color: AppColors.softLilac.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Device Connectivity',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Primary Devices label
                  Text(
                    'PRIMARY DEVICES',
                    style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.grey[400], letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Watch card
                  _DeviceCard(
                    icon:   Icons.watch,
                    type:   'WEARABLE',
                    name:   deviceStatus.watch.name,
                    status: deviceStatus.watch.status,
                    battery: health.watchBattery,
                    signal:  _levelToSignal(deviceStatus.watch.signalLevel),
                    onReconnect: () => ref.read(deviceStatusProvider.notifier).reconnect(),
                  ),
                  const SizedBox(height: 16),

                  // SIM unit card
                  _DeviceCard(
                    icon:    Icons.router,
                    type:    'BASE STATION',
                    name:    deviceStatus.simUnit.name,
                    status:  deviceStatus.simUnit.status,
                    battery: health.simBattery,
                    signal:  _levelToSignal(deviceStatus.simUnit.signalLevel),
                    onReconnect: () => ref.read(deviceStatusProvider.notifier).reconnect(),
                  ),
                  const SizedBox(height: 28),

                  // Global connectivity section
                  Text(
                    'GLOBAL CONNECTIVITY',
                    style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.grey[400], letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color:        AppColors.softLilac,
                      borderRadius: BorderRadius.circular(20),
                      border:       Border.all(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        _ToggleRow(
                          icon:    Icons.bluetooth,
                          label:   'Bluetooth',
                          toggled: deviceStatus.isAnyConnected,
                          divider: true,
                        ),
                        _ToggleRow(
                          icon:    Icons.wifi,
                          label:   'WiFi Discovery',
                          toggled: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Pair button at bottom
            Positioned(
              left: 24, right: 24, bottom: 100,
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => ref.read(deviceStatusProvider.notifier).reconnect(),
                    icon:  const Icon(Icons.add_circle_outline),
                    label: const Text('Pair New Device'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _levelToSignal(int level) {
    if (level >= 90) return 4;
    if (level >= 60) return 3;
    if (level >= 30) return 2;
    if (level > 0)   return 1;
    return 0;
  }
}

// ─── Device Card ─────────────────────────────────────────────────────────────
class _DeviceCard extends StatelessWidget {
  final IconData icon;
  final String type;
  final String name;
  final ConnectionStatus status;
  final int battery;
  final int signal;
  final VoidCallback onReconnect;

  const _DeviceCard({
    required this.icon,
    required this.type,
    required this.name,
    required this.status,
    required this.battery,
    required this.signal,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = status == ConnectionStatus.connected;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        AppColors.softLilac,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.04),
            blurRadius: 20, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.deepLavender, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: Colors.grey[500], letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                  ],
                ),
              ),
              ConnectionStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 14),
          if (isConnected) ...[
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    icon:  Icons.bar_chart,
                    label: 'Signal',
                    value: SignalBar(level: signal),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoChip(
                    icon:  Icons.battery_full,
                    label: 'Battery',
                    value: BatteryIndicator(percent: battery),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border:       Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Communication link lost. Ensure the unit is powered on.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onReconnect,
                    icon:  const Icon(Icons.refresh, size: 18),
                    label: const Text('Reconnect Unit'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Info chip ────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Widget   value;

  const _InfoChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w700,
              color: Colors.grey[500], letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          value,
        ],
      ),
    );
  }
}

// ─── Toggle row ──────────────────────────────────────────────────────────────
class _ToggleRow extends StatefulWidget {
  final IconData icon;
  final String   label;
  final bool     toggled;
  final bool     divider;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.toggled,
    this.divider = false,
  });

  @override
  State<_ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<_ToggleRow> {
  late bool _on;

  @override void initState() { super.initState(); _on = widget.toggled; }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(widget.icon, color: AppColors.deepLavender, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C1C1E),
                  ),
                ),
              ),
              Switch(
                value:     _on,
                onChanged: (v) => setState(() => _on = v),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ),
        if (widget.divider)
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.5)),
      ],
    );
  }
}
