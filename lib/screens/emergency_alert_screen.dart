// lib/screens/emergency_alert_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/app_theme.dart';
import '../core/constants/route_constants.dart';

class EmergencyAlertScreen extends ConsumerStatefulWidget {
  const EmergencyAlertScreen({super.key});

  @override
  ConsumerState<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends ConsumerState<EmergencyAlertScreen>
    with TickerProviderStateMixin {
  int     _countdown = 30;
  Timer?  _timer;
  bool    _dismissed = false;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_dismissed) return;
      if (_countdown <= 0) {
        _sendHelp();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _safePop() {
    if (_dismissed) return;
    if (!mounted) return;
    _dismissed = true;
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  void _sendHelp() {
    if (_dismissed) return;
    _timer?.cancel();
    _dismissed = true;
    Navigator.of(context).pushReplacementNamed(RouteConstants.sosSent);
  }

  void _iAmSafe() {
    if (_dismissed) return;
    _timer?.cancel();
    ref.read(healthDataProvider.notifier).reset();
    _safePop();
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(healthDataProvider);

    // Listen to fall detection becoming false to potentially auto-dismiss if user is safe
    ref.listen(fallAlertActiveProvider, (prev, next) {
      if (next == false && prev == true) {
        _safePop();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Status bar area
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:        AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.dangerRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'FALL DETECTION ACTIVE',
                          style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _iAmSafe,
                    icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Background glows
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Red glow top
                  Positioned(
                    top: -80,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 1.2,
                      height: 200,
                      decoration: BoxDecoration(
                        color:  AppColors.dangerRed.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(200),
                      ),
                    ),
                  ),
                  // Purple glow bottom
                  Positioned(
                    bottom: -60,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 1.2,
                      height: 200,
                      decoration: BoxDecoration(
                        color:  AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(200),
                      ),
                    ),
                  ),

                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pulsing danger icon
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, child) => Container(
                            width:  80 + _pulseCtrl.value * 20,
                            height: 80 + _pulseCtrl.value * 20,
                            decoration: BoxDecoration(
                              color:  AppColors.dangerRed.withValues(alpha: 0.08 + _pulseCtrl.value * 0.05),
                              shape:  BoxShape.circle,
                            ),
                            child: child,
                          ),
                          child: Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color:     AppColors.dangerRed,
                              shape:     BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:      AppColors.dangerRed.withOpacity(0.35),
                                  blurRadius: 24, offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.priority_high, color: Colors.white, size: 36),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Fall detected.\nAre you okay?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 34, fontWeight: FontWeight.w800,
                            color: const Color(0xFF1C1C1E),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 16, color: Colors.grey[500],
                              ),
                              children: [
                                const TextSpan(text: 'We detected a sudden impact. If you don\'t respond, we will alert your emergency contacts in '),
                                TextSpan(
                                  text: '00:${_countdown.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color:      AppColors.dangerRed,
                                    fontWeight: FontWeight.w700,
                                    fontSize:   18,
                                  ),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Heart rate + location mini-card
                        Container(
                          width: 280,
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                          decoration: BoxDecoration(
                            color:        Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border:       Border.all(color: AppColors.primary.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                color:      Colors.black.withOpacity(0.05),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'HEART RATE',
                                    style: GoogleFonts.inter(
                                      fontSize: 9, fontWeight: FontWeight.w700,
                                      color: Colors.grey[400], letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.favorite, color: AppColors.dangerRed, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${health.heartRate}',
                                        style: GoogleFonts.inter(
                                          fontSize: 22, fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        ' BPM',
                                        style: GoogleFonts.inter(
                                          fontSize: 11, color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 40, color: AppColors.primary.withOpacity(0.2)),
                              Column(
                                children: [
                                  Text(
                                    'LOCATION',
                                    style: GoogleFonts.inter(
                                      fontSize: 9, fontWeight: FontWeight.w700,
                                      color: Colors.grey[400], letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, color: AppColors.primary, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        health.gpsLat != 0.0 ? 'Tracked' : 'Unknown',
                                        style: GoogleFonts.inter(
                                          fontSize: 14, fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                  children: [
                    // SEND HELP
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, child) => Transform.scale(
                        scale: 1.0 + _pulseCtrl.value * 0.02,
                        child: child,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _sendHelp,
                        icon:  const Icon(Icons.sos, size: 28),
                        label: const Text('SEND HELP'),
                        style: ElevatedButton.styleFrom(
                          minimumSize:     const Size.fromHeight(64),
                          backgroundColor: AppColors.dangerRed,
                          foregroundColor: Colors.white,
                          shape:           const StadiumBorder(),
                          textStyle:       GoogleFonts.inter(
                            fontSize: 20, fontWeight: FontWeight.w800,
                          ),
                          elevation: 12,
                          shadowColor: AppColors.dangerRed.withOpacity(0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // I'm Safe
                    OutlinedButton(
                      onPressed: _iAmSafe,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(64),
                        foregroundColor: const Color(0xFF1C1C1E),
                        side:   const BorderSide(color: Color(0xFFE5E7EB), width: 2),
                        shape:  const StadiumBorder(),
                        textStyle: GoogleFonts.inter(
                          fontSize: 20, fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text("I'm Safe"),
                    ),
                    const SizedBox(height: 20),
                    // Contacts to notify
                    Text(
                      'CONTACTS TO BE NOTIFIED',
                      style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: Colors.grey[400], letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return Transform.translate(
                          offset: Offset(i * -12.0, 0),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color:  i < 2
                                  ? AppColors.primary
                                  : AppColors.primary.withOpacity(0.3),
                              shape:  BoxShape.circle,
                              border: Border.all(color: AppColors.bgLight, width: 3),
                            ),
                            child: Center(
                              child: i < 2
                                  ? Icon(Icons.person, color: Colors.white, size: 20)
                                  : Text(
                                      '+1',
                                      style: GoogleFonts.inter(
                                        fontSize: 11, fontWeight: FontWeight.w700,
                                        color: Colors.black54,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              )
            // (Return to Dashboard is now inside the _helpSent Column above)
          ],
        ),
      ),
    );
  }
}
