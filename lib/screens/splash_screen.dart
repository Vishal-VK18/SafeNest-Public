// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/blush_theme.dart';
import '../services/storage_service.dart';
import '../utils/dev_config.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/route_constants.dart';
import 'home_dashboard_screen.dart';
import 'home_wrapper.dart';
import 'onboarding/onboarding_screen.dart';

import '../core/services/auth_flow_manager.dart';

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
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    // 1000ms animation + 200ms delay as per HTML design = 1200ms total
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Lady animation starts after 200ms (0.166 interval of 1200ms)
    final curve = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.166, 1.0, curve: Curves.easeOut),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(curve);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05), // approx 16px relative to container
      end: Offset.zero,
    ).animate(curve);

    _ctrl.forward();

    // Determine initial route after splash animation
    Future.delayed(const Duration(seconds: 2), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    
    final destination = await AuthFlowManager.getInitialRoute();
    debugPrint('[SafeNest Splash] Determining route: $destination');

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(destination, (route) => false);
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
          // ── Blush gradient background ─────────────────────────────────────
          // linear-gradient(145deg, #FFB899 0%, #FFC8A8 40%, #FFCACB 100%)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFB899),
                    Color(0xFFFFC8A8),
                    Color(0xFFFFCACB),
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // ── Top Glow Softener ─────────────────────────────────────────────
          // radial-gradient(circle, rgba(255,215,180,0.45) 0%, transparent 70%)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.08,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFD7B4).withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA05028).withValues(alpha: 0.22),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/safenest_splash_lady.png',
                      fit: BoxFit.contain,
                    ),
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
