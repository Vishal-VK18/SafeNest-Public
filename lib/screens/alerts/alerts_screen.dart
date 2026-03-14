import 'package:flutter/material.dart';
import '../../core/constants/route_constants.dart';
import '../../core/navigation/page_transitions.dart';
import 'package:google_fonts/google_fonts.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Alerts',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF181818),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: GestureDetector(
            onTap: () {
            debugPrint('[SafeNest Nav] ← Back tapped: AlertsScreen');
            debugPrint('[SafeNest Nav] canPop: ${Navigator.of(context).canPop()}');
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
            } else {
              Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                RouteConstants.dashboard, (route) => false,
              );
            }
          },
          behavior: HitTestBehavior.opaque, // Added as per instruction
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.40),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.50),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF181818),
              size: 18,
            ),
          ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFC09D), // Top Blush
              Color(0xFFFFD6CC), // Mid Blush
              Color(0xFFFFCACB), // Bottom Blush
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC09D).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: Color(0xFFFFC09D),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No new alerts',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF181818),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You're all caught up. We'll notify you if we detect anything abnormal.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6B6B6B),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
