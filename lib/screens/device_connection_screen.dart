// lib/screens/device_connection_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../providers/system_providers.dart';
import '../models/device_status_model.dart';
import '../utils/app_theme.dart';
import '../utils/blush_theme.dart';

class DeviceConnectionScreen extends ConsumerStatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  ConsumerState<DeviceConnectionScreen> createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends ConsumerState<DeviceConnectionScreen> {
  @override
  Widget build(BuildContext context) {
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

    final deviceStatus     = ref.watch(deviceStatusProvider);
    final btStateAsync     = ref.watch(bluetoothStateProvider);
    final networkNameAsync = ref.watch(networkNameProvider);

    final isBluetoothOn = btStateAsync.value == BluetoothAdapterState.on;
    final networkName   = networkNameAsync.value ?? 'Checking...';
    final isWifiOn      = networkName != 'Disconnected' && networkName != 'Checking...';

    // Gradient Background from blush theme
    final gradientDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFFFC09D), const Color(0xFFFFCACB)],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF8), // creamy
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: gradientDecoration,
              child: Container(
                color: Colors.white.withOpacity(0.25), // Backdrop blur equivalent
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 40, height: 40,
                            alignment: Alignment.centerLeft,
                            child: const Icon(Icons.arrow_back_ios, color: Color(0xFF181818), size: 20),
                          ),
                        ),
                      ),
                      Text(
                        'Device Hub',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181818).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24, bottom: 24),
                    child: Text(
                      'Devices',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF181818),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 120),
                    child: Column(
                      children: [
                        // Watch Card
                        _buildDeviceCard(
                          type: 'Wearable',
                          icon: Icons.watch_rounded,
                          status: deviceStatus.watch.status,
                          onReconnect: () => ref.read(deviceStatusProvider.notifier).reconnect(),
                        ),
                        const SizedBox(height: 24),

                        // SIM Card
                        _buildDeviceCard(
                          type: 'SIM Module',
                          icon: Icons.sim_card_rounded,
                          status: deviceStatus.simUnit.status,
                          onReconnect: () => ref.read(deviceStatusProvider.notifier).reconnect(),
                        ),
                        const SizedBox(height: 24),

                        // System Toggles
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.5)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildToggleRow(
                                title: 'Bluetooth',
                                subtitle: isBluetoothOn ? 'Enabled' : 'Disabled',
                                subtitleColor: isBluetoothOn ? Colors.green[500]! : Colors.grey[500]!,
                                icon: Icons.bluetooth,
                                iconColor: Colors.blue[500]!,
                                iconBg: Colors.blue[50]!,
                                value: isBluetoothOn,
                                onChanged: (val) => ref.read(systemServiceProvider).turnOnBluetooth(),
                                showBorder: true,
                              ),
                              _buildToggleRow(
                                title: 'WiFi',
                                subtitle: isWifiOn ? 'Connected to WiFi' : 'Disconnected',
                                subtitleColor: isWifiOn ? Colors.green[500]! : Colors.grey[500]!,
                                icon: Icons.wifi,
                                iconColor: Colors.indigo[500]!,
                                iconBg: Colors.indigo[50]!,
                                value: isWifiOn,
                                onChanged: (val) => ref.read(systemServiceProvider).openWiFiSettings(),
                                showBorder: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard({
    required String type,
    required IconData icon,
    required ConnectionStatus status,
    required VoidCallback onReconnect,
  }) {
    final isConnected = status == ConnectionStatus.connected;
    final isConnecting = status == ConnectionStatus.connecting || status == ConnectionStatus.scanning;

    String statusText = 'Disconnected';
    Color statusColor = Colors.red[500]!;
    Color statusBg = Colors.red[50]!;
    Color statusBorder = Colors.red[100]!;

    if (isConnected) {
      statusText = 'Connected';
      statusColor = Colors.green[500]!;
      statusBg = Colors.green[50]!;
      statusBorder = Colors.green[100]!;
    } else if (isConnecting) {
      statusText = 'Connecting...';
      statusColor = Colors.orange[500]!;
      statusBg = Colors.orange[50]!;
      statusBorder = Colors.orange[100]!;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start, // Align to top
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC09D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: const Color(0xFFFFC09D), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: const Color(0xFF181818).withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isConnected ? 'Active Pair' : 'Not Paired',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF181818),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText.toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (!isConnected) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50], // Very light gray from UI
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    type == 'SIM Module' 
                        ? 'SIM module not connected.\nEnsure it is powered on and nearby.'
                        : 'Not Connected\nTap "Reconnect" to search.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.4), height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: isConnecting ? null : onReconnect,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: isConnecting ? null : const LinearGradient(colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)]),
                        color: isConnecting ? Colors.grey[300] : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isConnecting ? null : [
                          BoxShadow(color: const Color(0xFFFFC09D).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isConnecting)
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          else
                            const Icon(Icons.refresh, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isConnecting ? 'Connecting...' : 'Reconnect',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
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

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required Color subtitleColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool showBorder,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: showBorder ? Border(bottom: BorderSide(color: Colors.grey[100]!)) : null,
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF181818))),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: subtitleColor)),
                ],
              ),
            ],
          ),
          
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: value ? const Color(0xFFFFC09D) : Colors.grey[200],
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
