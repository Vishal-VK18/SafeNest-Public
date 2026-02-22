// lib/widgets/battery_indicator.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class BatteryIndicator extends StatelessWidget {
  final int percent;
  const BatteryIndicator({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = percent > 50
        ? AppColors.statusGreen
        : percent > 20
            ? AppColors.alertOrange
            : AppColors.dangerRed;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          percent > 75
              ? Icons.battery_full
              : percent > 50
                  ? Icons.battery_5_bar
                  : percent > 25
                      ? Icons.battery_3_bar
                      : Icons.battery_1_bar,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          '$percent%',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1C1E),
          ),
        ),
      ],
    );
  }
}
