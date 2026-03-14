// lib/widgets/journey_progress.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class JourneyProgress extends StatelessWidget {
  final int week;
  final int month;
  final int daysToGo;
  final double progress; // 0.0 to 1.0

  const JourneyProgress({
    super.key,
    required this.week,
    required this.month,
    required this.daysToGo,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background track
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 12,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFF8EEE9)),
                ),
              ),
              // Gradient-like progress (custom painter for better look)
              SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _GradientCircularPainter(
                    progress: progress,
                    backgroundColor: Colors.transparent,
                    color: AppColors.primary,
                  ),
                ),
              ),
              // Inner content
              Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'MONTH $month'.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE9A48E).withOpacity(0.6),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Week $week',
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFE9A48E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$daysToGo days to go',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFE9A48E).withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'THIRD TRIMESTER',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientCircularPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color color;

  _GradientCircularPainter({
    required this.progress,
    required this.backgroundColor,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Conic gradient effect (simplified to linear for now, but rotating it)
    paint.shader = SweepGradient(
      colors: [AppColors.blush, AppColors.primary],
      stops: const [0.0, 1.0],
      transform: const GradientRotation(-pi / 2),
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
