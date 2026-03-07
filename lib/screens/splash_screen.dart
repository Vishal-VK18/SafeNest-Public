// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import '../utils/blush_theme.dart';
import '../services/storage_service.dart';
import '../utils/dev_config.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/route_constants.dart';
import 'home_dashboard_screen.dart';
import 'home_wrapper.dart';
import 'onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fadeAnim;
  late Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();

    // Splash waits 3 seconds then routes.
    // Biometric auth happens inside HomeWrapper — NOT here.
    Future.delayed(const Duration(seconds: 3), _navigate);
  }

  void _navigate() {
    if (!mounted) return;

    if (kDevMode) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
      );
      return;
    }

    // ── PRODUCTION: full auth flow ────────────────────────────────────────
    final isOnboardingComplete = StorageService.isOnboardingComplete;
    if (!isOnboardingComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    final isLoggedIn = StorageService.isLoggedIn;
    Navigator.of(context).pushReplacementNamed(
      isLoggedIn ? RouteConstants.dashboard : RouteConstants.getStarted,
    );
  }


  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Blush gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: BlushGradients.background),
            ),
          ),
          // ── Content
          FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Logo ──────────────────────────────────────────────────
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Icon(Icons.favorite, color: Colors.white, size: 44),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── App name ───────────────────────────────────────────────
                Text(
                  'SafeNest',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize:      38,
                    fontWeight:    FontWeight.w600,
                    color:         Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Tagline ────────────────────────────────────────────────
                Text(
                  'Gentle care. Always connected.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize:      17,
                    fontWeight:    FontWeight.w400,
                    color:         Colors.white.withValues(alpha: 0.82),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 48),

                // ── Subtitle tagline ───────────────────────────────────────
                Text(
                  'MONITORING VITALS & SAFETY',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize:      10,
                    fontWeight:    FontWeight.w500,
                    letterSpacing: 3,
                    color:         Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),

                // ── iOS-style home indicator ───────────────────────────────
                Container(
                  width: 120,
                  height: 4,
                  decoration: BoxDecoration(
                    color:        Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ), // Close ScaleTransition
      ), // Close FadeTransition
        ], // Close Stack children
      ), // Close Stack
    ); // Close Scaffold
  }
}
