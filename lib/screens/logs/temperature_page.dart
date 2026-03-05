import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/providers.dart';
import '../../models/device_status_model.dart';
import '../../models/temperature_entry.dart';

class TemperaturePage extends ConsumerWidget {
  const TemperaturePage({super.key});

  // Strict Design System Colors
  static const Color primaryLilac = Color(0xFFBDB0D0);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color cardGray = Color(0xFFF5F5F7);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color successGreenTint = Color(0xFFE8F5E9);
  static const Color graphOrange = Color(0xFFFFAB40);
  static const Color mutedGray = Color(0xFF8E8E93);
  static const Color textBlack = Color(0xFF1C1C1E);
  static const Color alertRed = Color(0xFFF44336);
  static const Color alertRedTint = Color(0xFFFFEBEE);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthDataProvider);
    final deviceStatus = ref.watch(deviceStatusProvider);
    final tempLog = ref.watch(temperatureLogProvider);
    final isConnected = deviceStatus.watch.status == ConnectionStatus.connected;

    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        backgroundColor: backgroundWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          "Body Temp",
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textBlack,
          ),
        ),
        iconTheme: const IconThemeData(color: textBlack),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(isConnected),
              const SizedBox(height: 24),
              _buildMainTemperatureCard(health.temperature, health.isTemperatureNormal),
              const SizedBox(height: 16),
              _buildInfoCardsRow(health.receivedAt, health.isTemperatureNormal),
              const SizedBox(height: 32),
              _buildHistoryHeader(),
              const SizedBox(height: 16),
              _buildHistoryList(tempLog.take(3).toList()),
              const SizedBox(height: 32),
              _buildBottomButton(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isConnected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "LIVE MONITORING",
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primaryLilac,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isConnected ? successGreen : mutedGray,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected ? "Connected to Watch" : "Disconnected",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textBlack,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cardGray,
            shape: BoxShape.circle,
            border: Border.all(color: primaryLilac.withOpacity(0.2), width: 1),
          ),
          child: const Icon(Icons.person_outline, color: primaryLilac),
        ),
      ],
    );
  }

  Widget _buildMainTemperatureCard(double temperature, bool isNormal) {
    final tempDisplay = temperature > 0
        ? temperature.toStringAsFixed(1)
        : '--.-';
    final badgeText = temperature > 0 ? (isNormal ? "NORMAL" : "ALERT") : "WAITING";
    final badgeColor = temperature > 0
        ? (isNormal ? successGreen : alertRed)
        : mutedGray;
    final badgeBg = temperature > 0
        ? (isNormal ? successGreenTint : alertRedTint)
        : cardGray;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardGray,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "BODY TEMPERATURE",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: mutedGray,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
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
                tempDisplay,
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: textBlack,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "°C",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: mutedGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _TemperatureGraphPainter(color: graphOrange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardsRow(DateTime receivedAt, bool isNormal) {
    final hasData = receivedAt.year > 2000;
    final timeText = hasData
        ? DateFormat('hh:mm a').format(receivedAt)
        : '--:--';
    final statusText = hasData ? (isNormal ? 'Stable' : 'Elevated') : 'Waiting';

    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.access_time_filled_rounded,
            iconColor: primaryLilac,
            iconBg: primaryLilac.withOpacity(0.15),
            label: "LAST CHECK",
            value: timeText,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _InfoCard(
            icon: Icons.check_circle_rounded,
            iconColor: successGreen,
            iconBg: successGreen.withOpacity(0.15),
            label: "STATUS",
            value: statusText,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "TEMPERATURE HISTORY",
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: primaryLilac,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          "RECENT",
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: mutedGray,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(List<TemperatureEntry> entries) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            "No readings yet",
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: mutedGray,
            ),
          ),
        ),
      );
    }

    return Column(
      children: entries.asMap().entries.map((e) {
        final entry = e.value;
        final isNormal = entry.value >= 35.0 && entry.value < 37.5;
        final subtext = isNormal ? "Within normal range" : "Temperature elevated";
        final time = DateFormat('hh:mm a').format(entry.timestamp);
        final color = isNormal ? graphOrange : Colors.redAccent.shade100;

        return Padding(
          padding: EdgeInsets.only(bottom: e.key < entries.length - 1 ? 12 : 0),
          child: _HistoryItem(
            value: "${entry.value.toStringAsFixed(1)}°C",
            subtext: subtext,
            time: time,
            iconColor: color,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: primaryLilac,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryLilac.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => Navigator.pushNamed(context, RouteConstants.temperatureLog),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                "VIEW FULL LOG",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemperaturePage.cardGray,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: TemperaturePage.mutedGray,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: TemperaturePage.textBlack,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String value;
  final String subtext;
  final String time;
  final Color iconColor;

  const _HistoryItem({
    required this.value,
    required this.subtext,
    required this.time,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemperaturePage.cardGray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.thermostat_rounded, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TemperaturePage.textBlack,
                  ),
                ),
                Text(
                  subtext,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: TemperaturePage.mutedGray,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: TemperaturePage.mutedGray,
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
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    // Simple smooth curve representing temperature
    path.quadraticBezierTo(
      size.width * 0.2, size.height * 0.4,
      size.width * 0.4, size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.6, size.height * 0.8,
      size.width * 0.8, size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.9, size.height * 0.3,
      size.width, size.height * 0.4,
    );

    canvas.drawPath(path, paint);

    // Gradient fill below curve
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
