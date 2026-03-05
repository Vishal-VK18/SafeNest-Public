import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../providers/system_providers.dart';
import '../models/device_status_model.dart';
import '../utils/app_theme.dart';
import '../widgets/connection_status_badge.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/signal_bar.dart';

class DeviceConnectionScreen extends ConsumerStatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  ConsumerState<DeviceConnectionScreen> createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends ConsumerState<DeviceConnectionScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh every 2 seconds to pick up background BLE connection state
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceStatus     = ref.watch(deviceStatusProvider);
    final health           = ref.watch(healthDataProvider);
    final btStateAsync     = ref.watch(bluetoothStateProvider);
    final networkNameAsync = ref.watch(networkNameProvider);

    final isBluetoothOn = btStateAsync.value == BluetoothAdapterState.on;
    final networkName   = networkNameAsync.value ?? 'Checking...';

    if (!Platform.isAndroid && !Platform.isIOS) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Bluetooth not supported on this platform',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

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
                  color: AppColors.softLilac.withOpacity(0.4),
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
                  color: AppColors.softLilac.withOpacity(0.4),
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
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      ),
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
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── WEARABLE SECTION ─────────────────────────────────────
                  Text(
                    'WEARABLE DEVICE',
                    style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.grey[400], letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DeviceCard(
                    icon:    Icons.watch,
                    type:    'WEARABLE',
                    name:    deviceStatus.watch.isConnected
                        ? deviceStatus.watch.name
                        : FlutterBluePlus.connectedDevices.isNotEmpty
                            ? FlutterBluePlus.connectedDevices.first.platformName
                            : 'Not Paired',
                    status:  FlutterBluePlus.connectedDevices.isNotEmpty
                        ? ConnectionStatus.connected
                        : deviceStatus.watch.status,
                    battery: deviceStatus.watch.isConnected ? health.watchBattery : 0,
                    signal:  _levelToSignal(deviceStatus.watch.signalLevel),
                    onReconnect: () => ref.read(deviceStatusProvider.notifier).reconnect(),
                  ),
                  const SizedBox(height: 28),

                  // ── SIM MODULE SECTION ───────────────────────────────────
                  Text(
                    'SIM MODULE',
                    style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.grey[400], letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SimModuleCard(
                    status: health.simSignal > 0
                        ? ConnectionStatus.connected
                        : deviceStatus.simUnit.status,
                    name: health.simSignal > 0
                        ? 'SafeNest SIM'
                        : deviceStatus.simUnit.isConnected
                            ? deviceStatus.simUnit.name
                            : 'Not Paired',
                    battery: 0,
                    signal: health.simSignal,
                    networkType: health.networkType.isNotEmpty && health.networkType != 'N/A'
                        ? health.networkType
                        : '—',
                    simSignal: health.simSignal,
                    onReconnect: () => ref.read(deviceStatusProvider.notifier).reconnect(),
                  ),
                  const SizedBox(height: 28),

                  // ── GLOBAL CONNECTIVITY (Real Hardware) ─────────────────
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
                      border:       Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        _SystemToggleRow(
                          icon:    Icons.bluetooth,
                          label:   'Bluetooth',
                          status:  isBluetoothOn ? 'Enabled' : 'Disabled',
                          toggled: isBluetoothOn,
                          onToggle: (v) => ref.read(systemServiceProvider).turnOnBluetooth(),
                          divider: true,
                        ),
                        _SystemToggleRow(
                          icon:    Icons.wifi,
                          label:   'WiFi',
                          status:  networkName,
                          toggled: networkName != 'Disconnected' && networkName != 'Checking...',
                          onToggle: (v) => ref.read(systemServiceProvider).openWiFiSettings(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Pair / Scan Button ────────────────────────────────────────
            Positioned(
              left: 24, right: 24, bottom: 100,
              child: _PairButton(isEnabled: isBluetoothOn),
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

// ─── System Toggle Row ────────────────────────────────────────────────────────
class _SystemToggleRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   status;
  final bool     toggled;
  final Function(bool) onToggle;
  final bool     divider;

  const _SystemToggleRow({
    required this.icon,
    required this.label,
    required this.status,
    required this.toggled,
    required this.onToggle,
    this.divider = false,
  });

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
                child: Icon(icon, color: AppColors.deepLavender, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                    Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 11, color: toggled ? AppColors.statusGreen : Colors.grey,
                        fontWeight: toggled ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value:     toggled,
                onChanged: onToggle,
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ),
        if (divider)
          Divider(height: 1, color: Colors.white.withOpacity(0.5)),
      ],
    );
  }
}

// ─── Device Card (Watch) ──────────────────────────────────────────────────────
class _DeviceCard extends StatelessWidget {
  final IconData         icon;
  final String           type;
  final String           name;
  final ConnectionStatus status;
  final int              battery;
  final int              signal;
  final VoidCallback     onReconnect;

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
    final isConnected  = status == ConnectionStatus.connected;
    final isScanning   = status == ConnectionStatus.scanning;
    final isConnecting = status == ConnectionStatus.connecting;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        AppColors.softLilac,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
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
                      color: Colors.black.withOpacity(0.06),
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

          if (isScanning)
            _StateRow(
              icon: Icons.bluetooth_searching,
              message: 'Scanning for devices…',
              showSpinner: true,
            )
          else if (isConnecting)
            _StateRow(
              icon: Icons.bluetooth_connected,
              message: 'Connecting…',
              showSpinner: true,
            )
          else if (isConnected) ...[
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
                    value: battery > 0
                        ? BatteryIndicator(percent: battery)
                        : _BatteryUnknown(),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border:       Border.all(
                  color: AppColors.primary.withOpacity(0.4),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Not Connected\nTap "Pair New Device" to search.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onReconnect,
                    icon:  const Icon(Icons.refresh, size: 18),
                    label: const Text('Reconnect'),
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

// ─── SIM Module Card ────────────────────────────────────────────────────────
class _SimModuleCard extends StatelessWidget {
  final ConnectionStatus status;
  final String           name;
  final int              battery;
  final int              signal;
  final String           networkType;
  final int              simSignal;
  final VoidCallback     onReconnect;

  const _SimModuleCard({
    required this.status,
    required this.name,
    required this.battery,
    required this.signal,
    required this.networkType,
    required this.simSignal,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected  = status == ConnectionStatus.connected;
    final isScanning   = status == ConnectionStatus.scanning;
    final isConnecting = status == ConnectionStatus.connecting;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColors.primary.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14, offset: const Offset(0, 4),
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.sim_card, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SIM MODULE',
                      style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: Colors.grey[500], letterSpacing: 1.2,
                      )),
                    Text(name,
                      style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1C1E),
                      )),
                  ],
                ),
              ),
              ConnectionStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 14),

          if (isScanning || isConnecting)
            _StateRow(
              icon: Icons.signal_cellular_alt,
              message: isScanning ? 'Searching for SIM module…' : 'Connecting to SIM…',
              showSpinner: true,
            )
          else if (isConnected) ...[
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    icon:  Icons.network_cell,
                    label: 'Network',
                    value: Text(networkType,
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.lavenderText,
                      )),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoChip(
                    icon:  Icons.battery_full,
                    label: 'Battery',
                    value: battery > 0
                        ? BatteryIndicator(percent: battery)
                        : _BatteryUnknown(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoChip(
              icon:  Icons.signal_cellular_alt,
              label: 'Signal',
              value: Row(
                children: [
                  SignalBar(level: simSignal),
                  const SizedBox(width: 8),
                  Text(
                    simSignal >= 4 ? 'Excellent'
                        : simSignal >= 3 ? 'Good'
                        : simSignal >= 2 ? 'Fair'
                        : simSignal >= 1 ? 'Poor'
                        : 'No Signal',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: simSignal >= 3
                          ? AppColors.statusGreen
                          : simSignal >= 1
                              ? AppColors.alertOrange
                              : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        AppColors.softLilac.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    'SIM module not connected.\nEnsure it is powered on and nearby.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onReconnect,
                    icon:  const Icon(Icons.refresh, size: 18),
                    label: const Text('Reconnect'),
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

// ─── Pair Button ─────────────────────────────────────────────────────────────
class _PairButton extends ConsumerWidget {
  final bool isEnabled;
  const _PairButton({required this.isEnabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (!isEnabled)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.alertOrange, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Enable Bluetooth to scan',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.alertOrange, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ElevatedButton.icon(
          onPressed: isEnabled ? () => _openScanSheet(context, ref) : null,
          icon:  const Icon(Icons.add_circle_outline),
          label: const Text('Pair New Device'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: isEnabled ? AppColors.primary : Colors.grey[300],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  void _openScanSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScanSheet(
        onDeviceSelected: (device) async {
          Navigator.pop(context);
          await ref.read(bleServiceProvider).connectToDevice(device);
        },
      ),
    );
    ref.read(bleServiceProvider).startManualScan();
  }
}

// ─── Scan Sheet ───────────────────────────────────────────────────────────────
class _ScanSheet extends ConsumerWidget {
  final Future<void> Function(BluetoothDevice) onDeviceSelected;
  const _ScanSheet({required this.onDeviceSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanResultsAsync = ref.watch(bleScanResultsProvider);
    final scanningAsync    = ref.watch(bleScanningProvider);
    final isScanning       = scanningAsync.value ?? true;
    final results          = scanResultsAsync.value ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Available Devices', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1E))),
              const Spacer(),
              if (isScanning)
                Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    const SizedBox(width: 8),
                    Text('Scanning…', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary)),
                  ],
                )
              else
                TextButton.icon(
                  onPressed: () => ref.read(bleServiceProvider).startManualScan(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Rescan'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bluetooth_searching, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(isScanning ? 'Searching...' : 'No devices found', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400])),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = results[i];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: AppColors.softLilac, child: const Icon(Icons.bluetooth, color: AppColors.primary, size: 20)),
                        title: Text(r.device.platformName.isNotEmpty ? r.device.platformName : 'Unknown', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text('${r.device.remoteId.str} · ${r.rssi} dBm', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                        trailing: ElevatedButton(
                          onPressed: () => onDeviceSelected(r.device),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: const StadiumBorder(), minimumSize: const Size(0, 36)),
                          child: const Text('Connect'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared UI Helpers ───────────────────────────────────────────────────────
class _StateRow extends StatelessWidget {
  final IconData icon;
  final String   message;
  final bool     showSpinner;
  const _StateRow({required this.icon, required this.message, this.showSpinner = false});
  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          if (showSpinner) SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          else Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Text(message, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

class _BatteryUnknown extends StatelessWidget {
  @override Widget build(BuildContext context) => Text('—', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[400]));
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Widget   value;
  const _InfoChip({required this.icon, required this.label, required this.value});
  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1)),
          const SizedBox(height: 4),
          value,
        ],
      ),
    );
  }
}
