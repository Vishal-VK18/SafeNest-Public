// lib/screens/sim_module_status_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class SIMModuleStatusScreen extends StatefulWidget {
  const SIMModuleStatusScreen({super.key});

  @override
  State<SIMModuleStatusScreen> createState() => _SIMModuleStatusScreenState();
}

class _SIMModuleStatusScreenState extends State<SIMModuleStatusScreen> {
  bool isConnected = true;

  // Colors as per requirements
  static const Color pastelLilac = Color(0xFFBDB0D0);
  static const Color softGray = Color(0xFFF5F5F7);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color mutedCoral = Color(0xFFF4A48B); // Muted coral
  static const Color darkGray = Color(0xFF333333);
  static const Color lightBodyGray = Color(0xFF8E8E93);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "SIM Module Status",
          style: GoogleFonts.inter(
            color: darkGray,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Status Card
              _buildMainStatusCard(),
              const SizedBox(height: 32),

              // Connection Info Section
              Text(
                "Connection Info",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkGray,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoList(),
              const SizedBox(height: 24),

              // Informational Note
              Text(
                "The SIM module provides an independent connection for fall detection. This ensures emergency contacts are notified even if your smartphone is out of reach or powered off.",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: lightBodyGray,
                  fontWeight: FontWeight.w300,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Action Buttons
              ElevatedButton(
                onPressed: () {
                  // Simulate refresh
                  setState(() {
                    isConnected = !isConnected;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: pastelLilac,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Refresh Connection",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: pastelLilac,
                  side: const BorderSide(color: pastelLilac, width: 1.5),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  "Troubleshoot Connection",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isConnected ? softGray : mutedCoral.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: pastelLilac.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.signal_cellular_alt,
              color: pastelLilac,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isConnected ? "SIM Safety Module Connected" : "SIM Module Not Detected",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isConnected
                ? "Direct cellular connection is active."
                : "Alerts will be sent through the mobile app. Please ensure your phone is nearby.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: lightBodyGray,
              height: 1.4,
            ),
          ),
          if (isConnected) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatCapsule(
                    label: "Signal",
                    value: "Excellent (4/4)",
                    icon: Icons.wifi_tethering,
                    accentColor: successGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCapsule(
                    label: "Battery",
                    value: "88%",
                    icon: Icons.battery_charging_full,
                    accentColor: successGreen,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCapsule({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: lightBodyGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoList() {
    return Column(
      children: [
        _buildInfoItem("Provider", "Global SafeConnect"),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        _buildInfoItem("Network Type", "LTE-M (Low Power)"),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        _buildInfoItem("Last Sync", "2 minutes ago"),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: lightBodyGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: darkGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
