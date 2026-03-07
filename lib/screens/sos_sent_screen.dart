// lib/screens/sos_sent_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/bottom_nav_bar.dart';
import '../core/constants/route_constants.dart';

class SosSentScreen extends StatefulWidget {
  const SosSentScreen({super.key});

  @override
  State<SosSentScreen> createState() => _SosSentScreenState();
}

class _SosSentScreenState extends State<SosSentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFAE8E0), Color(0xFFF5D0C5)],
          ),
        ),
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildHeroPulse(),
                    const SizedBox(height: 24),
                    Text(
                      "SOS Sent Successfully",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D2D2D),
                        fontFamily: GoogleFonts.inter().fontFamily,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Help is on the way. Stay calm.",
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF8A8A8A),
                        fontFamily: GoogleFonts.inter().fontFamily,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildReassuranceCard(),
                    const SizedBox(height: 24),
                    _buildStatusCard(
                      icon: Icons.location_on,
                      title: "Location Shared",
                      subtitle: "Your GPS location has been sent",
                      badgeText: "SENT",
                      badgeColor: const Color(0xFF4CAF84),
                      badgeBg: const Color(0xFFE8F5EE),
                    ),
                    _buildStatusCard(
                      icon: Icons.phone_in_talk,
                      title: "Contacting Emergency Circle",
                      subtitle: "Your saved contacts are being notified",
                      badgeText: "ALERTING",
                      badgeColor: const Color(0xFFE8856A),
                      badgeBg: const Color(0xFFFDF0EC),
                      isPulsing: true,
                    ),
                    const SizedBox(height: 120), // For bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeNestBottomNavBar(
        selectedIndex: 3,
        onTabChange: (index, label) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, RouteConstants.dashboard);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, RouteConstants.journey);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, RouteConstants.devices);
              break;
            case 3:
              // Already here
              break;
            case 4:
              Navigator.pushReplacementNamed(context, RouteConstants.profile);
              break;
          }
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              "SOS Activated",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8856A).withOpacity(0.5 + (_pulseCtrl.value * 0.5)),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE8856A).withOpacity(0.3 * _pulseCtrl.value),
                        blurRadius: 4 * _pulseCtrl.value,
                        spreadRadius: 2 * _pulseCtrl.value,
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroPulse() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulse rings
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            return Container(
              width: 180 + (20 * _pulseCtrl.value),
              height: 180 + (20 * _pulseCtrl.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5C4B5).withOpacity(0.2 * (1 - _pulseCtrl.value)),
              ),
            );
          },
        ),
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF5C4B5).withOpacity(0.5),
          ),
        ),
        // Inner solid circle
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE8856A),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8856A).withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 8,
              )
            ],
          ),
          child: const Center(
            child: Text(
              "SOS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReassuranceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8856A).withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF5C4B5),
            ),
            child: const Icon(Icons.favorite, color: Color(0xFFE8856A)),
          ),
          const SizedBox(height: 12),
          Text(
            "You Are Not Alone \u{1F497}",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D2D2D),
              fontFamily: GoogleFonts.inter().fontFamily,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your emergency contacts have been alerted.\nNearest maternity support has been notified.\nStay calm, breathe slowly.\nHelp is on the way to you.",
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF8A8A8A),
              height: 1.6,
              fontFamily: GoogleFonts.inter().fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    bool isPulsing = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8856A).withOpacity(0.08),
            blurRadius: 12,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF5C4B5),
            ),
            child: Icon(icon, color: const Color(0xFFE8856A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
          ),
          _buildBadge(badgeText, badgeColor, badgeBg, isPulsing),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color, Color bg, bool isPulsing) {
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );

    if (isPulsing) {
      return AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          return Opacity(
            opacity: 0.6 + (_pulseCtrl.value * 0.4),
            child: child,
          );
        },
        child: badge,
      );
    }
    return badge;
  }
}
