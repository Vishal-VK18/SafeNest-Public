// lib/screens/journey/sleep_oxygen_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/providers.dart';
import '../../../utils/blush_theme.dart';

class SleepOxygenScreen extends ConsumerWidget {
  const SleepOxygenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleep = ref.watch(sleepOxygenProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sleep & Oxygen',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Blush gradient background
          Positioned.fill(
            child: Container(decoration: const BoxDecoration(gradient: BlushGradients.background)),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          children: [
            // Overall Sleep Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(
                    '${sleep.sleepDurationHours.toStringAsFixed(1)}h',
                    style: GoogleFonts.inter(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8E7DA0),
                      letterSpacing: -2.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EFFF),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, color: Color(0xFF8E7DA0), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'SLEEP QUALITY: ${ref.read(sleepOxygenProvider.notifier).calculateSleepScore()}/100',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8E7DA0),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sleep Phases Card
            _buildSection(
              title: 'SLEEP PHASES',
              trailing: 'Tonight',
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[50]!),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    // Segmented Bar
                    Container(
                      height: 48,
                      width: double.infinity,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          Expanded(flex: 25, child: Container(color: const Color(0xFFB9AAFF))),
                          Expanded(flex: 40, child: Container(color: const Color(0xFFD8CEFF))),
                          Expanded(flex: 10, child: Container(color: const Color(0xFFF3EFFF))),
                          Expanded(flex: 25, child: Container(color: const Color(0xFFD8CEFF))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLegendItem('Deep', const Color(0xFFB9AAFF)),
                        _buildLegendItem('Light', const Color(0xFFD8CEFF)),
                        _buildLegendItem('Awake', const Color(0xFFF3EFFF)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Oxygen Level Card
            _buildSection(
              title: 'OXYGEN LEVEL (SpO₂)',
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[50]!),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${sleep.averageSpO2.toStringAsFixed(0)}% ',
                                style: GoogleFonts.inter(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF8E7DA0),
                                ),
                              ),
                              TextSpan(
                                text: 'AVG',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sleep.averageSpO2 >= 95 ? Colors.green[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: sleep.averageSpO2 >= 95 ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                sleep.averageSpO2 >= 95 ? 'NORMAL' : 'WARNING',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: sleep.averageSpO2 >= 95 ? Colors.green[600] : Colors.red[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Oxygen Bar Chart
                    SizedBox(
                      height: 80,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          75, 80, 78, 92, 85, 82, 97, 89, 86, 84, 80, 85
                        ].map((heightPct) {
                          bool isActive = heightPct >= 92;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                height: 80 * (heightPct / 100),
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xFF8E7DA0) : const Color(0xFFD8CEFF),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Heart Rate Card
            _buildSection(
              title: 'SLEEP HEART RATE',
              titleRight: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '62 ',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text: 'BPM',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[50]!),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
                  ],
                ),
                child: Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EFFF).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomPaint(
                    painter: _EkgPainter(const Color(0xFFC9BCFF)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Insight Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EFFF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.health_and_safety, color: Color(0xFF8E7DA0)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PREGNANCY SAFETY INSIGHT',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8E7DA0),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pregnant women should maintain oxygen levels above 95%. Consistent readings below this may indicate sleep apnea, common in the third trimester.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8E7DA0),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, String? trailing, Widget? titleRight, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
                letterSpacing: 2.0,
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[400],
                ),
              ),
            if (titleRight != null) titleRight,
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _EkgPainter extends CustomPainter {
  final Color color;

  _EkgPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Recreating SVG path from HTML proportionately
    path.moveTo(0, size.height * 0.5);
    path.lineTo(size.width * 0.05, size.height * 0.5);
    path.lineTo(size.width * 0.0625, size.height * 0.3);
    path.lineTo(size.width * 0.0875, size.height * 0.7);
    path.lineTo(size.width * 0.1, size.height * 0.5);
    
    path.lineTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.2125, size.height * 0.2);
    path.lineTo(size.width * 0.2375, size.height * 0.8);
    path.lineTo(size.width * 0.25, size.height * 0.5);

    path.lineTo(size.width * 0.35, size.height * 0.5);
    path.lineTo(size.width * 0.3625, size.height * 0.4);
    path.lineTo(size.width * 0.3875, size.height * 0.6);
    path.lineTo(size.width * 0.4, size.height * 0.5);

    path.lineTo(size.width * 0.5, size.height * 0.5);
    path.lineTo(size.width * 0.5125, size.height * 0.35);
    path.lineTo(size.width * 0.5375, size.height * 0.65);
    path.lineTo(size.width * 0.55, size.height * 0.5);
    
    path.lineTo(size.width * 0.65, size.height * 0.5);
    path.lineTo(size.width * 0.6625, size.height * 0.45);
    path.lineTo(size.width * 0.6875, size.height * 0.55);
    path.lineTo(size.width * 0.7, size.height * 0.5);

    path.lineTo(size.width * 0.8, size.height * 0.5);
    path.lineTo(size.width * 0.8125, size.height * 0.3);
    path.lineTo(size.width * 0.8375, size.height * 0.7);
    path.lineTo(size.width * 0.85, size.height * 0.5);

    path.lineTo(size.width, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
