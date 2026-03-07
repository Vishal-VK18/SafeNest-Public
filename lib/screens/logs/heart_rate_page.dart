import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/route_constants.dart';

class HeartRatePage extends StatelessWidget {
  const HeartRatePage({super.key});

  // Strict Design System Colors
  static const Color primaryLilac = Color(0xFFBDB0D0);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color cardGray = Color(0xFFF5F5F7);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color successGreenTint = Color(0xFFE8F5E9);
  static const Color graphCoral = Color(0xFFF08080);
  static const Color mutedGray = Color(0xFF8E8E93);
  static const Color textBlack = Color(0xFF1C1C1E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          "Heart Rate",
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textBlack,
          ),
        ),
        iconTheme: const IconThemeData(color: textBlack),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFC09D),
              Color(0xFFFFCACB),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 24),
                _buildMainHeartRateCard(),
                const SizedBox(height: 16),
                _buildInfoCardsRow(),
                const SizedBox(height: 32),
                _buildHistoryHeader(),
                const SizedBox(height: 16),
                _buildHistoryList(),
                const SizedBox(height: 32),
                _buildBottomButton(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                  decoration: const BoxDecoration(
                    color: successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Connected to Watch",
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

  Widget _buildMainHeartRateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                "HEART RATE",
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
                  color: successGreenTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "NORMAL",
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: successGreen,
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
                "78",
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: textBlack,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "BPM",
                style: GoogleFonts.outfit(
                  fontSize: 16,
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
              painter: _HeartRateGraphPainter(color: graphCoral),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.access_time_filled_rounded,
            iconColor: primaryLilac,
            iconBg: primaryLilac.withOpacity(0.15),
            label: "LAST CHECK",
            value: "09:12 AM",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _InfoCard(
            icon: Icons.shield_rounded,
            iconColor: successGreen,
            iconBg: successGreen.withOpacity(0.15),
            label: "STATUS",
            value: "Stable",
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
          "HEART RATE HISTORY",
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textBlack,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          "LAST 3 HOURS",
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: mutedGray,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    return Column(
      children: [
        _HistoryItem(
          value: "78 BPM",
          subtext: "Within normal range",
          time: "09:12 AM",
          iconColor: Colors.redAccent.shade100,
        ),
        const SizedBox(height: 12),
        _HistoryItem(
          value: "72 BPM",
          subtext: "Resting state",
          time: "08:45 AM",
          iconColor: Colors.blueAccent.shade100,
        ),
        const SizedBox(height: 12),
        _HistoryItem(
          value: "82 BPM",
          subtext: "Light activity",
          time: "07:30 AM",
          iconColor: Colors.orangeAccent.shade100,
        ),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFC09D),
            Color(0xFFFFB6A5),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC09D).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.pushNamed(context, RouteConstants.heartRateLog),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.list_rounded, color: Colors.white),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
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
              color: HeartRatePage.mutedGray,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: HeartRatePage.textBlack,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_rounded, color: iconColor, size: 20),
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
                    color: HeartRatePage.textBlack,
                  ),
                ),
                Text(
                  subtext,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: HeartRatePage.mutedGray,
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
              color: HeartRatePage.mutedGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartRateGraphPainter extends CustomPainter {
  final Color color;

  _HeartRateGraphPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, size.height * 0.7);

    // Simple smooth curve representing heart rate
    path.quadraticBezierTo(
      size.width * 0.1, size.height * 0.8,
      size.width * 0.2, size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.1,
      size.width * 0.3, size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.4, size.height * 0.9,
      size.width * 0.5, size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.6, size.height * 0.2,
      size.width * 0.7, size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.8, size.height * 0.9,
      size.width * 0.9, size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.95, size.height * 0.2,
      size.width, size.height * 0.5,
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
