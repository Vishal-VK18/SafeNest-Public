// lib/widgets/hydration_card.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class HydrationCard extends StatelessWidget {
  final double currentLiters;
  final double totalLiters;

  const HydrationCard({
    super.key,
    required this.currentLiters,
    required this.totalLiters,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentLiters / totalLiters).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lilacAccent.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.water_drop, color: AppColors.lavenderText, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hydration Reminder',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lavenderText,
                      ),
                    ),
                    Text(
                      'ACTIVE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lavenderText.withOpacity(0.5),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep yourself and your baby hydrated. Aim for $totalLiters liters today.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.lavenderText.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                // Progress Bar
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${currentLiters}L OF ${totalLiters}L',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lavenderText.withOpacity(0.6),
                        letterSpacing: 1,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Log water logic
                      },
                      child: Text(
                        'LOG WATER',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lavenderText,
                          decoration: TextDecoration.underline,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
