import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/providers.dart';
import '../../models/device_status_model.dart';
import '../../models/temperature_entry.dart';
import 'temperature_log_page.dart';

class TemperaturePage extends ConsumerWidget {
  const TemperaturePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthDataProvider);
    final deviceStatus = ref.watch(deviceStatusProvider);
    final tempLog = ref.watch(temperatureLogProvider);
    final isConnected = deviceStatus.watch.status == ConnectionStatus.connected;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLiveStatus(isConnected),
                        const SizedBox(height: 32),
                        _buildMainTemperatureCard(health.temperature, health.isTemperatureNormal),
                        const SizedBox(height: 16),
                        _buildInfoCardsRow(health.receivedAt, health.isTemperatureNormal),
                        const SizedBox(height: 32),
                        _buildHistoryCard(tempLog.take(3).toList()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating Button at Bottom
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: _buildBottomButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.centerLeft,
              child: const Icon(Icons.arrow_back, color: Color(0xFF181818), size: 24),
            ),
          ),
          Text(
            'Body Temp',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF181818),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE5DA),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF181818), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatus(bool isConnected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "LIVE MONITORING",
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: const Color(0xFF181818).withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.circle, color: isConnected ? Colors.green : const Color(0xFF6B6B6B), size: 10),
            const SizedBox(width: 6),
            Text(
              isConnected ? "Connected" : "Disconnected",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B6B6B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainTemperatureCard(double temperature, bool isNormal) {
    final tempDisplay = temperature > 0 ? temperature.toStringAsFixed(1) : '--.-';
    final badgeText = temperature > 0 ? (isNormal ? "NORMAL" : "ELEVATED") : "WAITING";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "BODY TEMPERATURE",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: const Color(0xFF181818).withOpacity(0.4),
                  ),
                ),
                Text(
                  badgeText,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: const Color(0xFF181818).withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  tempDisplay,
                  style: GoogleFonts.inter(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -2,
                    color: const Color(0xFF181818),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "°C",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181818).withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 96,
            width: double.infinity,
            child: CustomPaint(
              painter: _TemperatureGraphPainter(color: const Color(0xFF1F3F3F)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardsRow(DateTime receivedAt, bool isNormal) {
    final hasData = receivedAt.year > 2000;
    final timeText = hasData ? DateFormat('hh:mm a').format(receivedAt) : '--:--';
    final statusText = hasData ? (isNormal ? 'Normal' : 'Elevated') : 'Waiting';
    final statusColor = hasData && !isNormal ? const Color(0xFFFF9E80) : const Color(0xFF181818);
    final statusIconColor = hasData && !isNormal ? const Color(0xFFFF9E80) : const Color(0xFF181818);

    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.schedule,
            iconColor: const Color(0xFF181818),
            label: "LAST CHECK",
            value: timeText,
            valueColor: const Color(0xFF181818),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _InfoCard(
            icon: Icons.check_circle,
            iconColor: statusIconColor,
            label: "STATUS",
            value: statusText,
            valueColor: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(List<TemperatureEntry> entries) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "TEMPERATURE HISTORY",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: const Color(0xFF181818).withOpacity(0.4),
                  ),
                ),
                Text(
                  "RECENT",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: const Color(0xFF181818).withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: const Color(0xFF181818).withOpacity(0.05)),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  "No readings yet",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9A9A9A),
                  ),
                ),
              ),
            )
          else
            Column(
              children: entries.map((e) {
                final isNormal = e.value >= 35.0 && e.value < 37.5;
                final subtext = isNormal ? "Within normal range" : "Elevated reading";
                final time = DateFormat('hh:mm a').format(e.timestamp);
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFE5DA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.device_thermostat, color: Color(0xFF181818), size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${e.value.toStringAsFixed(1)}°C",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF181818),
                              ),
                            ),
                            Text(
                              subtext,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B6B6B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B6B6B),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TemperatureLogPage(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1F3D3D),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "VIEW FULL LOG",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE5DA),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: const Color(0xFF181818).withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemperatureGraphPainter extends CustomPainter {
  final Color color;

  _TemperatureGraphPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFC09D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, size.height * 0.75);

    path.cubicTo(
      size.width * 0.2, size.height * 0.75,
      size.width * 0.3, size.height * 0.65,
      size.width * 0.5, size.height * 0.65,
    );
    path.cubicTo(
      size.width * 0.7, size.height * 0.65,
      size.width * 0.8, size.height * 0.7,
      size.width, size.height * 0.7,
    );

    canvas.drawPath(path, paint);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFC09D).withOpacity(0.3),
          const Color(0xFFFFC09D).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
