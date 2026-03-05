import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../models/device_status_model.dart';
import '../core/constants/route_constants.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthDataProvider);
    final pregnancy = ref.watch(pregnancyProvider);
    final deviceState = ref.watch(deviceStatusProvider);

    final isConnected = deviceState.watch.status == ConnectionStatus.connected;
    final hasData = health.receivedAt.year > 2000;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Foggy Gradient Background
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
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.8),
                    Colors.white.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Status Bar Area (Simulated 9:41 etc skipped for system status bar, but header starts below)
                
                // Header Profile
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                              image: const DecorationImage(
                                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDxUahFZlLNPAFNq6UMAo6AhmVyEcbrAw9JrWGNMU0Zj1QWPwC_-dtX6XKTzfePUG6v4ut9P4ww6C2pkRR-tK0ACDfpzRaP-yTdCPqbJzJ7OR0_yGJaISJWceJKVcEGPVnFG-vt3aQRzsBvHEL-P43TS2N5veQ4V_l3XJlhtbiTSvqYfdm6t5x0-vFhMOFzkl-UoxPaj3vOQmA0R4vP3LEk2SeK4HIeGKNzVy3dofWxTJI199OsVZbH3aFtAdZYCYyQqVGrcq0JPiIP'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pregnancy.userName.isNotEmpty ? pregnancy.userName : 'Alison Barry',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF181818)),
                              ),
                              Text(
                                '27 years old',
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF181818).withOpacity(0.5)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, RouteConstants.alerts),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.6)),
                          ),
                          child: Icon(Icons.notifications_outlined, color: const Color(0xFF181818).withOpacity(0.7), size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Health metrics', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500, color: const Color(0xFF181818))),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/history'),
                                child: Text('View all', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.4))),
                              ),
                            ],
                          ),
                        ),

                        // Main Body Temperature Card
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, RouteConstants.temperature),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0x99FFC09D), Color(0x99FFCACB)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.4)),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: -1)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                                      child: const Icon(Icons.device_thermostat, color: Colors.white, size: 20),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(999)),
                                      child: Text(
                                        isConnected && hasData ? (health.isTemperatureNormal ? 'STABLE' : 'ALERT') : 'WAITING',
                                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white.withOpacity(0.8)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      isConnected && hasData ? health.temperature.toStringAsFixed(1) : '--.-',
                                      style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1, color: const Color(0xFF181818)),
                                    ),
                                    const SizedBox(width: 4),
                                    Text('°C', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFF181818).withOpacity(0.6))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Body Temperature', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.5))),
                                const SizedBox(height: 32),
                                // Sine wave approximation
                                SizedBox(
                                  height: 56,
                                  width: double.infinity,
                                  child: CustomPaint(
                                    painter: _SineWavePainter(color: const Color(0xFF181818).withOpacity(0.2)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 2-Column Grid (Heart Rate & Hydration)
                        Row(
                          children: [
                            // Heart Rate
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pushNamed(context, RouteConstants.heartRate),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 24, spreadRadius: -1)],
                                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x33FFCACB), Colors.transparent]),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.favorite, color: Color(0xFFFF6B6B), size: 24),
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            isConnected && hasData ? '${health.heartRate}' : '--',
                                            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF181818)),
                                          ),
                                          const SizedBox(width: 4),
                                          Text('bpm', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.4))),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Heart Rate', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.5))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Hydration
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pushNamed(context, RouteConstants.hydration),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 24, spreadRadius: -1)],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.water_drop, color: Colors.blue[400], size: 24),
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            '3/8', // Example static mapped data or dynamic if available in model
                                            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF181818)),
                                          ),
                                          const SizedBox(width: 4),
                                          Text('cups', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.4))),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Hydration', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.5))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Sleep Quality Strip
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, RouteConstants.sleep),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.5)),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 24, spreadRadius: -1)],
                              gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0x1AFFC09D), Colors.transparent]),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white),
                                      ),
                                      child: Icon(Icons.nights_stay, color: Colors.indigo[400], size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('6h 45m', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF181818))),
                                        Text('Last night sleep', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.5))),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(999)),
                                  child: Text('GOOD QUALITY', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: const Color(0xFF4CAF50))),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Fall Detection Status Box
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, RouteConstants.fallEventLog),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [BoxShadow(color: Color(0x0CFFC09D), blurRadius: 24, spreadRadius: 0)],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Fall Detection', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF181818))),
                                        Text(health.fallDetected ? 'Fall detected!' : 'All systems operational', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.4))),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: health.fallDetected ? Colors.red : const Color(0xFF4CAF50),
                                            shape: BoxShape.circle,
                                            boxShadow: [BoxShadow(color: (health.fallDetected ? Colors.red : const Color(0xFF4CAF50)).withOpacity(0.6), blurRadius: 8)],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          health.fallDetected ? 'DETECTED' : 'NO ISSUES',
                                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: health.fallDetected ? Colors.red : const Color(0xFF4CAF50)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Weekdays Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildDayIndicator('M', false),
                                    _buildDayIndicator('T', false),
                                    _buildDayIndicator('W', false),
                                    _buildDayIndicator('TH', true), // Assuming today is Thursday like the HTML hardcodes it
                                    _buildDayIndicator('F', false),
                                    _buildDayIndicator('S', false),
                                    _buildDayIndicator('S', false),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 120), // Padding for bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayIndicator(String label, bool isToday) {
    return Container(
      width: isToday ? 40 : 32,
      height: isToday ? 40 : 32,
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFF181818) : Colors.transparent,
        shape: BoxShape.circle,
        boxShadow: isToday ? [BoxShadow(color: const Color(0xFF181818).withOpacity(0.2), blurRadius: 10)] : null,
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
            color: isToday ? Colors.white : const Color(0xFF181818).withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}

// Sparkline Painter for Body Temperature graph
class _SineWavePainter extends CustomPainter {
  final Color color;

  _SineWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.75);
    path.cubicTo(
      size.width * 0.1, size.height * 0.75,
      size.width * 0.2, size.height * 0.65,
      size.width * 0.3, size.height * 0.65,
    );
    path.cubicTo(
      size.width * 0.45, size.height * 0.65,
      size.width * 0.55, size.height * 0.35,
      size.width * 0.65, size.height * 0.35,
    );
    path.cubicTo(
      size.width * 0.85, size.height * 0.35,
      size.width * 0.85, size.height * 0.75,
      size.width, size.height * 0.75,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
