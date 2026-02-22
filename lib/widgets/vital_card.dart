// lib/widgets/vital_card.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class VitalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String statusLabel;
  final bool isAlert;

  const VitalCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit       = '',
    this.statusLabel = 'Normal',
    this.isAlert    = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isAlert ? AppColors.dangerRed : AppColors.statusGreen;
    final statusBg    = isAlert
        ? AppColors.dangerRed.withOpacity(0.1)
        : AppColors.statusGreen.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAlert
              ? AppColors.dangerRed.withOpacity(0.3)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color:  AppColors.primary.withOpacity(0.2),
              shape:  BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:        statusBg,
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              statusLabel.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
