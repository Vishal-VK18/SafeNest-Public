// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_dashboard_screen.dart';

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

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              children: [
                // Decorative top glow
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft background glows
                      Positioned(
                        bottom: -40, left: -60,
                        child: Container(
                          width: 250, height: 250,
                          decoration: BoxDecoration(
                            color:  Colors.white.withOpacity(0.05),
                            shape:  BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 40, right: -30,
                        child: Container(
                          width: 180, height: 180,
                          decoration: BoxDecoration(
                            color:  Colors.white.withOpacity(0.05),
                            shape:  BoxShape.circle,
                          ),
                        ),
                      ),
                      // Main branding
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                              color:  Colors.white.withOpacity(0.1),
                              shape:  BoxShape.circle,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 90, height: 90,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 6,
                                    ),
                                    shape:        BoxShape.circle,
                                  ),
                                ),
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 44,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          // App name
                          Text(
                            'SafeNest',
                            style: GoogleFonts.inter(
                              fontSize:   38,
                              fontWeight: FontWeight.w600,
                              color:      Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Gentle care. Always connected.',
                            style: GoogleFonts.inter(
                              fontSize:   17,
                              fontWeight: FontWeight.w400,
                              color:      Colors.white.withOpacity(0.82),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Bottom branding
                Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Column(
                    children: [
                      Text(
                        'MONITORING VITALS & SAFETY',
                        style: GoogleFonts.inter(
                          fontSize:      10,
                          fontWeight:    FontWeight.w500,
                          letterSpacing: 3,
                          color:         Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // iOS-style home indicator
                      Container(
                        width: 120, height: 4,
                        decoration: BoxDecoration(
                          color:        Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
