// lib/screens/journey_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../utils/app_theme.dart';
import '../widgets/journey_progress.dart';
import '../widgets/hydration_card.dart';
import '../widgets/baby_size_card.dart';

class JourneyTab extends ConsumerWidget {
  const JourneyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancy = ref.watch(pregnancyProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              Text(
                'Pregnancy Journey',
                style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.lavenderText,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                icon: const Icon(Icons.more_horiz, color: AppColors.lavenderText),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (!pregnancy.hasData)
            _buildStartDatePrompt(context, ref)
          else ...[
            // ── Main Progress Circle ───────────────────────────────────────
            Center(
              child: JourneyProgress(
                week:      pregnancy.pregnancyWeek,
                month:     pregnancy.pregnancyMonth,
                daysToGo:  pregnancy.daysToGo,
                progress:  pregnancy.progressFraction,
              ),
            ),
            const SizedBox(height: 32),

            // ── Due Date Card ──────────────────────────────────────────────
            _buildDueDateCard(pregnancy.estimatedDueDateLabel),
            const SizedBox(height: 24),

            // ── Hydration ──────────────────────────────────────────────────
            const HydrationCard(currentLiters: 1.9, totalLiters: 3.0),
            const SizedBox(height: 24),

            // ── Size Card ──────────────────────────────────────────────────
            const BabySizeCard(
              sizeTitle:   'As big as an Eggplant',
              description: 'Your baby is about 14.8 inches long and weighs nearly 2.2 pounds.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDueDateCard(String dateLabel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softLilac),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.softLilac,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.calendar_today, color: AppColors.lavenderText),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTIMATED DUE DATE',
                  style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.lavenderText.withOpacity(0.4),
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  dateLabel,
                  style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.lavenderText,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStartDatePrompt(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_month, size: 64, color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            'Track Your Journey',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Set your pregnancy start date to see your progress and estimated due date.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _selectStartDate(context, ref),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Set Start Date'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 140)), // Mid-pregnancy default
      firstDate: now.subtract(const Duration(days: 300)),
      lastDate: now,
    );
    if (date != null) {
      ref.read(pregnancyProvider.notifier).updateStartDate(date);
    }
  }
}
