import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/providers.dart';
import '../../models/safety_event_model.dart';
import '../../utils/app_theme.dart';

class FallEventLogScreen extends ConsumerWidget {
  const FallEventLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safetyEvents = ref.watch(safetyHistoryProvider);
    final fallEvents = safetyEvents
        .where((e) => e.type == SafetyEventType.fall)
        .toList();

    const coral = Color(0xFFE9A48E);
    const green = Color(0xFF3DBB7C);
    const dark  = Color(0xFF181818);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: dark, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                      Expanded(
                        child: Text(
                          'Fall Event Log',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: dark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                // Summary bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryTile(
                          value: fallEvents.length.toString(),
                          label: 'Total Falls',
                          color: fallEvents.isEmpty ? green : const Color(0xFFE57373),
                        ),
                        _SummaryTile(
                          value: fallEvents.where((e) {
                            final today = DateTime.now();
                            return e.timestamp.year == today.year &&
                                e.timestamp.month == today.month &&
                                e.timestamp.day == today.day;
                          }).length.toString(),
                          label: 'Today',
                          color: dark,
                        ),
                        _SummaryTile(
                          value: fallEvents.isEmpty ? 'Safe' : 'Alert',
                          label: 'Status',
                          color: fallEvents.isEmpty ? green : const Color(0xFFE57373),
                        ),
                      ],
                    ),
                  ),
                ),

                // List
                Expanded(
                  child: fallEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: green.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle_outline,
                                    color: green, size: 40),
                              ),
                              const SizedBox(height: 16),
                              Text('No fall events recorded',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: dark)),
                              const SizedBox(height: 8),
                              Text('The wearable is actively monitoring.',
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: Colors.grey[500])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: fallEvents.length,
                          itemBuilder: (context, index) {
                            final event = fallEvents[index];
                            final months = ['JAN','FEB','MAR','APR','MAY','JUN',
                                'JUL','AUG','SEP','OCT','NOV','DEC'];
                            final t = event.timestamp;
                            final dateStr =
                                '${t.day} ${months[t.month - 1]} ${t.year} · '
                                '${t.hour.toString().padLeft(2,'0')}:'
                                '${t.minute.toString().padLeft(2,'0')}';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: coral.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.warning_amber_rounded,
                                        color: coral,
                                        size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Fall Detected',
                                            style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: dark)),
                                        const SizedBox(height: 2),
                                        Text(dateStr,
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.grey[500])),
                                        if (event.description.isNotEmpty)
                                          Text(event.description,
                                              style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: Colors.grey[400])),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: coral.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text('Alert',
                                        style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: coral)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryTile({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: Colors.grey[500])),
      ],
    );
  }
}
