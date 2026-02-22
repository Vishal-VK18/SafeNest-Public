// lib/widgets/signal_bar.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SignalBar extends StatelessWidget {
  final int level; // 0–4
  const SignalBar({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final label = ['No Signal', 'Poor', 'Fair', 'Good', 'Excellent'];
    final activeColor = AppColors.primary;
    const inactiveColor = Color(0xFFE5E7EB);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...List.generate(4, (i) {
          final h = 8.0 + i * 4.0;
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Container(
              width: 6,
              height: h,
              decoration: BoxDecoration(
                color:        i < level ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 6),
        Text(
          level <= 4 ? label[level] : 'N/A',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C1C1E),
          ),
        ),
      ],
    );
  }
}
