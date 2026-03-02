// lib/screens/journey_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../utils/app_theme.dart';

class JourneyTab extends ConsumerWidget {
  final void Function(int)? onSwitchTab;
  const JourneyTab({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancy = ref.watch(pregnancyProvider);
    final riskScore = ref.watch(riskScoreProvider);
    final riskStatus = ref.watch(riskStatusProvider);
    final analytics = ref.watch(weeklyAnalyticsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2EFFF),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF5D51A8)),
          onPressed: () {
            // Journey lives in an IndexedStack — switch back to Dashboard tab
            if (onSwitchTab != null) {
              onSwitchTab!(0);
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        title: Text(
          'Pregnancy Journey',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D51A8),
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF5D51A8)),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: !pregnancy.hasData
          ? Center(child: _buildStartDatePrompt(context, ref))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              child: Column(
                children: [
                   // ── Main Progress Circle ───────────────────────────────────────
                  _buildProgressCircle(pregnancy),

                  // ── Quarter Badge ────────────────────────────────────────────────
                  Container(
                    margin: const EdgeInsets.only(top: 32, bottom: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBDB0D0),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _getTrimesterLabel(pregnancy.pregnancyWeek),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  // ── Due Date Card ──────────────────────────────────────────────
                  _buildDueDateCard(context, ref, pregnancy),
                  const SizedBox(height: 16),

                  // ── Intelligent Banners ────────────────────────────────────────
                  if (riskScore >= 2) _buildRiskBanner(riskScore, riskStatus),
                  if (analytics['isSunday'] == true) _buildWeeklyAnalytics(analytics),

                  // ── Dynamic Baby Size Card ───────────────────────────────────────────
                  _buildSizeCard(pregnancy.pregnancyWeek),
                  const SizedBox(height: 16),

                  // ── Hydration & Sleep Grid ─────────────────────────────────────
                  Row(
                    children: [
                      Expanded(child: _buildHydrationGridCard(context, ref)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSleepGridCard(context, ref)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Next Checkup ───────────────────────────────────────────────
                  _buildNextCheckupCard(context),
                ],
              ),
            ),
    );
  }

  // ============== HELPER WIDGETS ==============

  Widget _buildProgressCircle(dynamic pregnancy) {
    return Container(
      width: 256,
      height: 256,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Ring
          Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF5F3FF), width: 12),
            ),
          ),
          // Progress Ring (Simulated with CircularProgressIndicator for simplicity)
          SizedBox(
            width: 256,
            height: 256,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: pregnancy.progressFraction),
              duration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 12,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBDB0D0)), // Pastel lilac
                );
              },
            ),
          ),
          // Inner White Circle with Text
          Container(
            width: 192,
            height: 192,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'MONTH ${pregnancy.pregnancyMonth}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5D51A8).withOpacity(0.6),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Week ${pregnancy.pregnancyWeek}',
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF5D51A8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${pregnancy.daysToGo} days to go',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5D51A8).withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateCard(BuildContext context, WidgetRef ref, dynamic pregnancy) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5F3FF)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF5D51A8)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTIMATED DUE DATE',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5D51A8).withOpacity(0.4),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pregnancy.estimatedDueDateLabel ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5D51A8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF5D51A8)),
            onPressed: () => _editStartDate(context, ref, pregnancy.startDate),
          ),
        ],
      ),
    );
  }

  Future<void> _editStartDate(BuildContext context, WidgetRef ref, DateTime? currentStartDate) async {
    final now = DateTime.now();
    // Validate date range (cannot exceed 42 weeks)
    final firstSelectionDate = now.subtract(const Duration(days: 294)); 
    
    // Show confirmation dialog first
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Edit Pregnancy Date?',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF5D51A8)),
          ),
          content: Text(
            'Changing the pregnancy start date will update all tracking data.\n\nDo you want to continue?',
            style: GoogleFonts.inter(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D51A8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Continue', style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final date = await showDatePicker(
      context: context,
      initialDate: currentStartDate ?? now.subtract(const Duration(days: 140)),
      firstDate: firstSelectionDate,
      lastDate: now, // No future dates allowed
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5D51A8),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      ref.read(pregnancyProvider.notifier).updateStartDate(date);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Baby Size Lookup Table (weeks 1–42)
  // ──────────────────────────────────────────────────────────────────────────
  static const Map<int, Map<String, String>> _babySizeMap = {
    1:  {'name': 'Poppy Seed',    'length': '0.04 in (1mm)',   'weight': 'Less than 1 gram'},
    2:  {'name': 'Sesame Seed',   'length': '0.06 in (1.5mm)', 'weight': 'Less than 1 gram'},
    3:  {'name': 'Blueberry',     'length': '0.1 in (2.5mm)',  'weight': 'Less than 1 gram'},
    4:  {'name': 'Poppy Seed',    'length': '0.2 in (5mm)',    'weight': 'Less than 1 gram'},
    5:  {'name': 'Apple Seed',    'length': '0.3 in (8mm)',    'weight': 'Less than 1 gram'},
    6:  {'name': 'Sweet Pea',     'length': '0.5 in (1.3cm)',  'weight': 'Less than 1 gram'},
    7:  {'name': 'Blueberry',     'length': '0.6 in (1.6cm)',  'weight': '0.03 oz'},
    8:  {'name': 'Kidney Bean',   'length': '0.63 in (1.6cm)', 'weight': '0.04 oz'},
    9:  {'name': 'Grape',         'length': '0.9 in (2.3cm)',  'weight': '0.07 oz'},
    10: {'name': 'Kumquat',       'length': '1.2 in (3cm)',    'weight': '0.14 oz'},
    11: {'name': 'Fig',           'length': '1.6 in (4.1cm)',  'weight': '0.25 oz'},
    12: {'name': 'Lime',          'length': '2.1 in (5.4cm)',  'weight': '0.49 oz'},
    13: {'name': 'Pea Pod',       'length': '2.9 in (7.4cm)',  'weight': '0.81 oz'},
    14: {'name': 'Lemon',         'length': '3.4 in (8.7cm)',  'weight': '1.52 oz'},
    15: {'name': 'Apple',         'length': '4.0 in (10.1cm)', 'weight': '2.47 oz'},
    16: {'name': 'Avocado',       'length': '4.6 in (11.6cm)', 'weight': '3.53 oz'},
    17: {'name': 'Pear',          'length': '5.1 in (13cm)',   'weight': '4.94 oz'},
    18: {'name': 'Bell Pepper',   'length': '5.6 in (14.2cm)', 'weight': '6.7 oz'},
    19: {'name': 'Mango',         'length': '6.0 in (15.3cm)', 'weight': '8.47 oz'},
    20: {'name': 'Banana',        'length': '6.5 in (16.4cm)', 'weight': '10.58 oz'},
    21: {'name': 'Pomegranate',   'length': '10.5 in (26.7cm)','weight': '12.7 oz'},
    22: {'name': 'Papaya',        'length': '10.9 in (27.8cm)','weight': '15.17 oz'},
    23: {'name': 'Grapefruit',    'length': '11.4 in (28.9cm)','weight': '1.1 lb'},
    24: {'name': 'Ear of Corn',   'length': '11.8 in (30cm)',  'weight': '1.3 lb'},
    25: {'name': 'Cauliflower',   'length': '13.6 in (34.6cm)','weight': '1.5 lb'},
    26: {'name': 'Lettuce Head',  'length': '14.0 in (35.6cm)','weight': '1.7 lb'},
    27: {'name': 'Rutabaga',      'length': '14.4 in (36.6cm)','weight': '1.9 lb'},
    28: {'name': 'Eggplant',      'length': '14.8 in (37.6cm)','weight': '2.2 lb'},
    29: {'name': 'Butternut Squash','length': '15.2 in (38.6cm)','weight': '2.5 lb'},
    30: {'name': 'Cabbage',       'length': '15.7 in (39.9cm)','weight': '2.9 lb'},
    31: {'name': 'Coconut',       'length': '16.2 in (41.1cm)','weight': '3.3 lb'},
    32: {'name': 'Jicama',        'length': '16.7 in (42.4cm)','weight': '3.8 lb'},
    33: {'name': 'Pineapple',     'length': '17.2 in (43.7cm)','weight': '4.2 lb'},
    34: {'name': 'Cantaloupe',    'length': '17.7 in (45cm)',  'weight': '4.7 lb'},
    35: {'name': 'Honeydew Melon','length': '18.2 in (46.2cm)','weight': '5.3 lb'},
    36: {'name': 'Romaine Lettuce','length': '18.7 in (47.4cm)','weight': '5.8 lb'},
    37: {'name': 'Swiss Chard',   'length': '19.1 in (48.6cm)','weight': '6.3 lb'},
    38: {'name': 'Leek',          'length': '19.6 in (49.8cm)','weight': '6.8 lb'},
    39: {'name': 'Mini Watermelon','length': '20.0 in (50.7cm)','weight': '7.3 lb'},
    40: {'name': 'Small Pumpkin', 'length': '20.2 in (51.2cm)','weight': '7.6 lb'},
    41: {'name': 'Pumpkin',       'length': '20.4 in (51.7cm)','weight': '7.9 lb'},
    42: {'name': 'Watermelon',    'length': '20.7 in (52.5cm)','weight': '8.0+ lb'},
  };

  Widget _buildSizeCard(int pregnancyWeek) {
    final week = pregnancyWeek.clamp(1, 42);
    final data = _babySizeMap[week] ?? _babySizeMap[28]!;
    final fruitName = data['name']!;
    final length    = data['length']!;
    final weight    = data['weight']!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8C7FB2), Color(0xFFBDB0D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "THIS WEEK'S SIZE",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'As big as a $fruitName',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: Text(
                  'About $length long and weighs $weight.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.child_care,
              size: 120,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBanner(int score, String status) {
    final isHighRisk = score >= 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighRisk ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHighRisk ? Colors.red.shade200 : Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: isHighRisk ? Colors.red : Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: isHighRisk ? Colors.red.shade700 : Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyAnalytics(Map<String, dynamic> analytics) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5F3FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Health Overview', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF5D51A8))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Avg Hydration', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                Text('${analytics['avgHydration']} L', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF5D51A8))),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Avg Sleep', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                Text('${analytics['avgSleepDuration']} h', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF5D51A8))),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Avg SpO2', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                Text('${analytics['avgSpO2']}%', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF5D51A8))),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHydrationGridCard(BuildContext context, WidgetRef ref) {
    // ── SINGLE SOURCE OF TRUTH: same provider + goal formula as HydrationTrackerScreen ──
    final hyd  = ref.watch(hydrationProvider);
    final preg = ref.watch(pregnancyProvider);
    final double goal =
        preg.pregnancyWeek <= 13 ? 2.5 : (preg.pregnancyWeek <= 26 ? 2.8 : 3.0);
    final fraction = (hyd.intakeLiters / goal).clamp(0.0, 1.0);
    final int pct  = (fraction * 100).toInt();

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/hydration'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF5F3FF)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: fraction,
                    strokeWidth: 4,
                    backgroundColor: const Color(0xFFF5F3FF),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBDB0D0)),
                  ),
                  const Icon(Icons.water_drop_outlined, color: Color(0xFF5D51A8)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'HYDRATION',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5D51A8).withOpacity(0.4),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${hyd.intakeLiters.toStringAsFixed(1)}L / ${goal.toStringAsFixed(1)}L',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5D51A8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$pct% REACHED',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5D51A8).withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepGridCard(BuildContext context, WidgetRef ref) {
    final sleep = ref.watch(sleepOxygenProvider);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/sleep'),
      child: Container(
        height: 155, // Match hydration card approx
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F8FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF5F3FF)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(Icons.bedtime_outlined, color: Color(0xFF5D51A8), size: 16),
                const SizedBox(width: 8),
                Text(
                  'SLEEP INSIGHT',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5D51A8).withOpacity(0.4),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${sleep.sleepDurationHours.toStringAsFixed(1)}h',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A3F92),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  sleep.sleepDurationHours < 7 ? 'Rest needed' : 'Good rest',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF5D51A8).withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  sleep.sleepDurationHours < 7 ? Icons.trending_down : Icons.trending_up, 
                  size: 14, 
                  color: sleep.sleepDurationHours < 7 ? Colors.redAccent : Colors.greenAccent
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextCheckupCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/appointment'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF5F3FF)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.event_note_outlined, color: Color(0xFFBDB0D0)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEXT CHECKUP',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5D51A8).withOpacity(0.4),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dr. Helena Smith',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5D51A8),
                        ),
                      ),
                      Text(
                        'October 12, 2024',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF5D51A8).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: const Color(0xFF5D51A8).withOpacity(0.3)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '3 Days Remaining',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFBDB0D0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.75,
                backgroundColor: const Color(0xFFF5F3FF),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBDB0D0)),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/appointment'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFFBDB0D0),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(
                'VIEW DETAILS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTrimesterLabel(int weeks) {
    if (weeks < 13) return 'FIRST TRIMESTER';
    if (weeks < 27) return 'SECOND TRIMESTER';
    return 'THIRD TRIMESTER';
  }

  Widget _buildStartDatePrompt(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
