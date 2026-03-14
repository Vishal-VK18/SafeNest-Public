import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../providers/providers.dart';
import '../core/constants/route_constants.dart';
import 'journey/appointment_details_screen.dart';

class JourneyTab extends ConsumerWidget {
  final void Function(int)? onSwitchTab;
  const JourneyTab({super.key, this.onSwitchTab});

  (String, String, Widget) _getBabySizeData(int week) {
    if (week <= 4) return ('POPPY SEED', 'BABY IS THE SIZE OF A', const Icon(Icons.fiber_manual_record, size: 12, color: Colors.black87));
    if (week <= 8) return ('RASPBERRY', 'BABY IS THE SIZE OF A', const Icon(Icons.lens, size: 24, color: Colors.pinkAccent));
    if (week <= 12) return ('PLUM', 'BABY IS THE SIZE OF A', const Icon(Icons.lens, size: 48, color: const Color(0xFFFFC09D)));
    if (week <= 16) return ('AVOCADO', 'BABY IS THE SIZE OF AN', const Icon(Icons.lens, size: 64, color: Colors.green));
    if (week <= 20) return ('BANANA', 'BABY IS THE LENGTH OF A', const Icon(Icons.lens, size: 96, color: Colors.yellow));
    if (week <= 24) return ('CANTALOUPE', 'BABY IS THE SIZE OF A', const Icon(Icons.lens, size: 120, color: Colors.orangeAccent));
    if (week <= 28) return ('EGGPLANT', 'BABY IS THE SIZE OF AN', const Icon(Icons.lens, size: 140, color: const Color(0xFFFFC09D)));
    if (week <= 32) return ('SQUASH', 'BABY IS THE SIZE OF A', const Icon(Icons.lens, size: 160, color: Colors.yellowAccent));
    if (week <= 36) return ('HONEYDEW', 'BABY IS THE SIZE OF A', const Icon(Icons.lens, size: 180, color: Colors.lightGreen));
    return ('PUMPKIN', 'BABY IS THE SIZE OF A', const Icon(Icons.lens, size: 200, color: Colors.orange));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancy = ref.watch(pregnancyProvider);

    return Stack(
      children: [
        // Background Gradient
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)],
              ),
            ),
          ),
        ),
        // Frosted Glass Layer over gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.45),
            ),
            // Filter blur could be added, but standard container with opacity mimics the effect well enough without heavy backdrop filter on the entire screen
          ),
        ),

        // Main Scrollable Content
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (onSwitchTab != null) {
                            onSwitchTab!(0);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          width: 40, height: 40,
                          color: Colors.transparent,
                          alignment: Alignment.centerLeft,
                          child: const Icon(Icons.chevron_left, color: Color(0xFF181818), size: 28),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "PREGNANCY JOURNEY",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: const Color(0xFF181818).withOpacity(0.4),
                          ),
                        ),
                      ),
                      // Calendar icon — opens date picker to set pregnancy start date
                      GestureDetector(
                        onTap: () async {
                          final now = DateTime.now();
                          final initial = pregnancy.startDate ?? now.subtract(const Duration(days: 154));
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: now.subtract(const Duration(days: 300)),
                            lastDate: now,
                            helpText: 'SELECT PREGNANCY START DATE',
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFFFFC09D),
                                    onPrimary: Colors.white,
                                    surface: Color(0xFFFFFDFB),
                                    onSurface: Color(0xFF181818),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            ref.read(pregnancyProvider.notifier).updateStartDate(picked);
                          }
                        },
                        child: Container(
                          width: 40, height: 40,
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.calendar_month,
                            color: const Color(0xFF181818).withOpacity(0.5),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress Circle & Trimester Pill
                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Circle
                      SizedBox(
                        width: 280, height: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background Track
                            CustomPaint(
                              size: const Size(224, 224),
                              painter: _CircleTrackPainter(),
                            ),
                            // Progress Track
                            CustomPaint(
                              size: const Size(224, 224),
                              painter: _CircleProgressPainter(progress: (pregnancy.pregnancyWeek / 40.0).clamp(0.0, 1.0)),
                            ),
                            // Inner Box
                            Container(
                              width: 196, height: 196,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFDFB).withOpacity(0.6),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.4)),
                                boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12)],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'MONTH',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.5, color: const Color(0xFF181818).withOpacity(0.3)),
                                  ),
                                  Text(
                                    '${(pregnancy.pregnancyWeek / 4.3).ceil()}', // Approximating month from week
                                    style: GoogleFonts.plusJakartaSans(fontSize: 84, fontWeight: FontWeight.w800, height: 1.0, color: const Color(0xFF181818)),
                                  ),
                                  Text(
                                    '${40 - pregnancy.pregnancyWeek > 0 ? ((40 - pregnancy.pregnancyWeek)/4.3).ceil() : 0} Months Remaining',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.5)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Trimester Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDFB).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withOpacity(0.9)),
                        ),
                        child: Text(
                          _getTrimesterLabel(pregnancy.pregnancyWeek).toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: const Color(0xFFE89E8E)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Week & Size Card (Pineapple styling)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDFB).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.8)),
                    boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 30, offset: Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Week ${pregnancy.pregnancyWeek}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF181818), letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.3), letterSpacing: 1.5),
                          children: [
                            TextSpan(text: '${_getBabySizeData(pregnancy.pregnancyWeek).$2} '),
                            TextSpan(text: _getBabySizeData(pregnancy.pregnancyWeek).$1, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF181818))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Dynamic graphic approximation based on week mapping mapping exactly to the HTML graphic box size
                      SizedBox(
                        width: 192, height: 192,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            _getBabySizeData(pregnancy.pregnancyWeek).$3,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Estimated Due Date — read-only, auto-calculated from start date
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDFB).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.8)),
                    boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 30, offset: Offset(0, 10))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: const Color(0xFFFFC09D).withOpacity(0.15), borderRadius: BorderRadius.circular(18)),
                        child: const Icon(Icons.calendar_today, color: Color(0xFFFFC09D), size: 24),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ESTIMATED DUE DATE', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF181818).withOpacity(0.3), letterSpacing: 1.5)),
                          const SizedBox(height: 4),
                          Text(pregnancy.estimatedDueDateLabel, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF181818))),
                        ],
                      ),
                    ],
                  ),
                ),

                // Next Checkup
                Consumer(
                  builder: (context, ref, child) {
                    final nextAppt = ref.watch(nextUpcomingAppointmentProvider);
                    if (nextAppt == null) return const SizedBox.shrink();

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AppointmentDetailsScreen()),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 40),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDFB).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.8)),
                          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 30, offset: Offset(0, 10))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(color: const Color(0xFFFFCACB).withOpacity(0.2), borderRadius: BorderRadius.circular(18)),
                                  child: const Icon(Icons.medical_services, color: Color(0xFFFFCACB), size: 24),
                                ),
                                const SizedBox(width: 20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('NEXT CHECKUP', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF181818).withOpacity(0.3), letterSpacing: 1.5)),
                                    const SizedBox(height: 4),
                                    Text(nextAppt.doctorName.isNotEmpty ? nextAppt.doctorName : 'Add Doctor Name', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF181818))),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(DateFormat('MMM d, yyyy').format(nextAppt.date), style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.4))),
                                        Container(margin: const EdgeInsets.symmetric(horizontal: 8), width: 4, height: 4, decoration: BoxDecoration(color: const Color(0xFF181818).withOpacity(0.2), shape: BoxShape.circle)),
                                        Text('${nextAppt.date.difference(DateTime.now()).inDays} Days Remaining', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFFC09D))),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Icon(Icons.chevron_right, color: const Color(0xFF181818).withOpacity(0.2)),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Motivational Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Text(
                        'You are stronger than you think, and every day brings you closer to meeting your little miracle.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF181818).withOpacity(0.3), height: 1.6),
                      ),
                      const SizedBox(height: 12),
                      Container(width: 128, height: 6, decoration: BoxDecoration(color: const Color(0xFF181818).withOpacity(0.05), borderRadius: BorderRadius.circular(999))),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Padding for bottom nav bar

              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getTrimesterLabel(int week) {
    if (week <= 13) return 'First Trimester';
    if (week <= 26) return 'Second Trimester';
    return 'Third Trimester';
  }
}


class _CircleTrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 112, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  _CircleProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: 112);
    final gradient = const LinearGradient(colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)]).createShader(rect);
    final paint = Paint()
      ..shader = gradient
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    // -90 degrees is top. Sweep is 360 * progress
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}