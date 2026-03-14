import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../models/hydration_model.dart';
import '../../../providers/providers.dart';
import '../../../services/hydration_reminder_service.dart';
import '../../../widgets/safe_nest_bottom_navigation.dart';
import '../../../core/constants/route_constants.dart';


class HydrationTrackerScreen extends ConsumerStatefulWidget {
  final int initialPage;
  const HydrationTrackerScreen({super.key, this.initialPage = 0});

  @override
  ConsumerState<HydrationTrackerScreen> createState() => _HydrationTrackerScreenState();
}

class _HydrationTrackerScreenState extends ConsumerState<HydrationTrackerScreen> {
  final _reminderSvc = HydrationReminderService.instance;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _reminderSvc.init();
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _addWater(double liters) {
    ref.read(hydrationProvider.notifier).addEntry(liters);
  }

  Future<void> _onReminderToggle(bool enabled) async {
    ref.read(hydrationProvider.notifier).setReminder(enabled: enabled);
    if (enabled) {
      final freq = ref.read(hydrationProvider).reminderFreqHours;
      await _reminderSvc.scheduleReminder(frequencyHours: freq);
    } else {
      await _reminderSvc.cancelReminder();
    }
  }

  void goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFB),
      extendBody: true,
      resizeToAvoidBottomInset: false,

      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _HydrationDashboardSlide(
            onAddWater: (amt) => _addWater(amt / 1000.0),
            onGoToStats: () => goToPage(1),
            onGoToReminders: () => goToPage(2),
            onPop: () => Navigator.pop(context),
            ref: ref,
          ),
          _HydrationStatsSlide(
            onBack: () => goToPage(0),
          ),
          _HydrationRemindersSlide(
            onBack: () => goToPage(0),
            onToggleReminders: _onReminderToggle,
            ref: ref,
          ),
        ],
      ),
      bottomNavigationBar: const SafeNestBottomNavigation(),
    );
  }



}

// -----------------------------------------------------------------------------
// SLIDE 1: DASHBOARD
// Exactly matches: safenest_hydration_dashboard\code.html
// -----------------------------------------------------------------------------
class _HydrationDashboardSlide extends StatelessWidget {
  final Function(double) onAddWater;
  final VoidCallback onGoToStats;
  final VoidCallback onGoToReminders;
  final VoidCallback onPop;
  final WidgetRef ref;

  const _HydrationDashboardSlide({
    required this.onAddWater,
    required this.onGoToStats,
    required this.onGoToReminders,
    required this.onPop,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final hyd = ref.watch(hydrationProvider);
    final preg = ref.watch(pregnancyProvider);
    final double goal = preg.pregnancyWeek <= 13 ? 2.5 : (preg.pregnancyWeek <= 26 ? 2.8 : 3.0);
    final fraction = (hyd.intakeLiters / goal).clamp(0.0, 1.0);
    final int percent = (fraction * 100).toInt();

    return Stack(
      children: [
        // diffused-bg base
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)], // peach to blush
              ),
            ),
          ),
        ),
        // blur overlay
        Positioned.fill(
          child: Container(
            color: const Color(0xFFFFFDFB).withOpacity(0.4),
          ),
        ),
        // animated fluid blobs static approximations
        Positioned(
          top: -100, right: -40,
          child: Container(
            width: 256, height: 256,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC09D).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 100, left: -40,
          child: Container(
            width: 288, height: 288,
            decoration: BoxDecoration(
              color: const Color(0xFFFFCACB).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        debugPrint('[SafeNest Nav] ← Back tapped: HydrationTrackerScreen');
                        debugPrint('[SafeNest Nav] canPop: ${Navigator.of(context).canPop()}');
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else if (Navigator.of(context, rootNavigator: true).canPop()) {
                          Navigator.of(context, rootNavigator: true).pop();
                        } else {
                          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                            RouteConstants.dashboard, (route) => false,
                          );
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.40),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.50),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF181818),
                          size: 18,
                        ),
                      ),
                    ),
                    // Title
                    Text(
                      'Hydration Tracker',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181818),
                      ),
                    ),
                    // Bell icon
                    GestureDetector(
                      onTap: onGoToReminders,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.notifications_none, color: Color(0xFF181818), size: 22),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),

                  child: Column(
                    children: [
                      // Progress Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                          boxShadow: [BoxShadow(color: const Color(0xFFFFC09D).withOpacity(0.15), blurRadius: 32, offset: const Offset(0, 8))],
                        ),
                        child: Column(
                          children: [
                            // SVG approximation
                            SizedBox(
                              width: 208, height: 208,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(size: const Size(208, 208), painter: _HydrationRingTrackPainter()),
                                  CustomPaint(size: const Size(208, 208), painter: _HydrationRingProgressPainter(progress: fraction)),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            hyd.intakeLiters.toStringAsFixed(1),
                                            style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -0.5),
                                          ),
                                          Text(
                                            'L',
                                            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A).withOpacity(0.5)),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'of ${goal.toStringAsFixed(1)}L',
                                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC09D).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$percent% Completed',
                                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[500]),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Daily Goal: ${goal.toStringAsFixed(1)} Liters',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),

                      // Buttons Row
                      Row(
                        children: [
                          Expanded(child: _buildAddBtn(Icons.water_drop, '+ 250 ml', () => onAddWater(250))),
                          const SizedBox(width: 16),
                          Expanded(child: _buildAddBtn(Icons.local_drink, '+ 500 ml', () => onAddWater(500))),
                          const SizedBox(width: 16),
                          Expanded(child: _buildAddBtn(Icons.opacity, '+ 1 L', () => onAddWater(1000))),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Intake Summary (goes to stats)
                      GestureDetector(
                        onTap: onGoToStats,
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: Colors.white.withOpacity(0.4)),
                            boxShadow: [BoxShadow(color: const Color(0xFFFFC09D).withOpacity(0.15), blurRadius: 32, offset: const Offset(0, 8))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Intake Summary', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                                  const Icon(Icons.more_horiz, color: Color(0xFF94A3B8)),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildVerticalBar('Morning', 0.85),
                                  _buildVerticalBar('Afternoon', 0.40),
                                  _buildVerticalBar('Evening', 0.15),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
          boxShadow: [BoxShadow(color: const Color(0xFFFFC09D).withOpacity(0.15), blurRadius: 32)],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFFC09D), size: 24),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalBar(String label, double fill) {
    return Column(
      children: [
        Container(
          width: 48, height: 112,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9).withOpacity(0.5),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            height: 112 * fill,
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFFFFC09D), Color(0xFFFFD5BC)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(999), bottom: Radius.circular(999)),
              boxShadow: [BoxShadow(color: Color(0x4DFFC09D), blurRadius: 10, offset: Offset(0, -4))],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B), letterSpacing: 0.5)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// SLIDE 2: STATS
// exactly matches: safenest_hydration_stats\code.html
// -----------------------------------------------------------------------------
class _HydrationStatsSlide extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const _HydrationStatsSlide({required this.onBack});

  @override
  ConsumerState<_HydrationStatsSlide> createState() => _HydrationStatsSlideState();
}

class _HydrationStatsSlideState extends ConsumerState<_HydrationStatsSlide> {
  int _selectedStatTab = 1; // 0 = Day, 1 = Week, 2 = Month

  double _getChartMax() => _selectedStatTab == 0 ? 5.0 : (_selectedStatTab == 1 ? 25.0 : 100.0);
  
  List<double> _getMockDataForTab() {
    final hyd = ref.watch(hydrationProvider);
    // Since hydration history mapping might be empty initially, we can safely simulate realistic fallback bounds
    if (_selectedStatTab == 0) return [0.5, 0.8, 1.2, 2.0, 1.5, 0.4, 0.0];
    if (_selectedStatTab == 1) return [14.0, 16.1, 12.5, 18.0, 15.5, 19.0, 11.0];
    return [60.0, 75.0, 68.0, 80.0, 95.0, 88.0, 72.0];
  }

  String _getChartTitle() {
    if (_selectedStatTab == 0) return 'DAILY WATER INTAKE';
    if (_selectedStatTab == 1) return 'WEEKLY WATER INTAKE';
    return 'MONTHLY WATER INTAKE';
  }

  String _getChartValue() {
    final hyd = ref.watch(hydrationProvider);
    if (_selectedStatTab == 0) return hyd.intakeLiters.toStringAsFixed(1);
    if (_selectedStatTab == 1) return '16.1';
    return '74.5';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // diffused-bg base (Same as Dashboard)
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)], // peach to blush
              ),
            ),
          ),
        ),
        // blur overlay
        Positioned.fill(
          child: Container(
            color: const Color(0xFFFFFDFB).withOpacity(0.4),
          ),
        ),
        
        SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: widget.onBack,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                        child: const Icon(Icons.chevron_left, color: Color(0xFF475569)),
                      ),
                    ),
                    Text('Hydration Statistics', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF181818))),
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                      child: const Icon(Icons.share, color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedStatTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: _selectedStatTab == 0 ? BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x1AFFC09D), blurRadius: 14, offset: Offset(0, 4))]) : null,
                            child: Center(child: Text('Day', style: GoogleFonts.inter(fontSize: 14, fontWeight: _selectedStatTab == 0 ? FontWeight.bold : FontWeight.w500, color: _selectedStatTab == 0 ? const Color(0xFF1E293B) : const Color(0xFF64748B)))),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedStatTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: _selectedStatTab == 1 ? BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x1AFFC09D), blurRadius: 14, offset: Offset(0, 4))]) : null,
                            child: Center(child: Text('Week', style: GoogleFonts.inter(fontSize: 14, fontWeight: _selectedStatTab == 1 ? FontWeight.bold : FontWeight.w500, color: _selectedStatTab == 1 ? const Color(0xFF1E293B) : const Color(0xFF64748B)))),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedStatTab = 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: _selectedStatTab == 2 ? BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x1AFFC09D), blurRadius: 14, offset: Offset(0, 4))]) : null,
                            child: Center(child: Text('Month', style: GoogleFonts.inter(fontSize: 14, fontWeight: _selectedStatTab == 2 ? FontWeight.bold : FontWeight.w500, color: _selectedStatTab == 2 ? const Color(0xFF1E293B) : const Color(0xFF64748B)))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),

                  child: Column(
                    children: [
                      // Weekly Chart
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 8))],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_getChartTitle(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B), letterSpacing: 1.0)),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(_getChartValue(), style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                                        Text(' L', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.green[100]!)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.trending_up, color: Colors.green, size: 14),
                                      const SizedBox(width: 4),
                                      Text('+12%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[700])),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Bar chart static exact height mapping
                            SizedBox(
                              height: 176,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: _getMockDataForTab()
                                    .map((val) => _buildStatBar(val / _getChartMax()))
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: (_selectedStatTab == 0 ? ['6A', '9A', '12P', '3P', '6P', '9P', '12A'] :
                                       (_selectedStatTab == 1 ? ['M', 'T', 'W', 'T', 'F', 'S', 'S'] :
                                        ['W1', 'W2', 'W3', 'W4', 'W1', 'W2', 'W3']))
                                  .map((d) {
                                return Expanded(child: Center(child: Text(d, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8)))));
                              }).toList(),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // List Items
                      _buildStatRowCard(icon: Icons.water_drop, title: 'AVERAGE DAILY INTAKE', value: '2.3 L'),
                      const SizedBox(height: 16),
                      _buildStatRowCard(icon: Icons.emoji_events, title: 'BEST HYDRATION DAY', value: 'Wednesday (3.2 L)'),
                      const SizedBox(height: 16),
                      _buildStatRowCard(icon: Icons.verified, title: 'CONSISTENCY SCORE', value: '85% / 100'),
                      
                      const SizedBox(height: 48), // Padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBar(double heightFactor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFC09D).withOpacity(0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 176 * heightFactor,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFFFFC09D), Color(0xFFFFB6A5)]),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRowCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFFFFC09D).withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(icon, color: const Color(0xFFFFC09D)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 1.0)),
                  Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                ],
              ),
            ],
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SLIDE 3: REMINDERS
// Exactly matches: safenest_hydration_reminders\code.html
// -----------------------------------------------------------------------------
class _HydrationRemindersSlide extends StatelessWidget {
  final VoidCallback onBack;
  final Future<void> Function(bool) onToggleReminders;
  final WidgetRef ref;

  const _HydrationRemindersSlide({required this.onBack, required this.onToggleReminders, required this.ref});

  @override
  Widget build(BuildContext context) {
    final hyd = ref.watch(hydrationProvider);

    return Scaffold( // We use an inner scaffold due to inner scrolling list structure matching HTML
      backgroundColor: const Color(0xFFFFF9F6),
      body: Stack(
        children: [
          // exact diffused gradient bg
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)]),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.6, -0.4),
                  radius: 1.0,
                  colors: [Colors.white.withOpacity(0.4), Colors.transparent],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: onBack,
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                          child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF334155), size: 18),
                        ),
                      ),
                      Text('Hydration Reminders', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 110),
                    child: Column(
                      children: [
                        // Progress Circle
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 240, height: 240,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(size: const Size(240, 240), painter: _RemindersRingTrackPainter()),
                                    CustomPaint(size: const Size(240, 240), painter: _RemindersRingProgressPainter(progress: 800/2210)),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('800 / 2210', style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B), letterSpacing: -0.5)),
                                        Text('ml today', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                                ),
                                child: Text('Almost halfway there! 🌿', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF334155))),
                              ),
                            ],
                          ),
                        ),

                        // Rest of settings wrap
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Smart Reminders', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                                      Text('Based on your activity & goals', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
                                    ],
                                  ),
                                  Switch(
                                    value: hyd.reminderEnabled,
                                    onChanged: onToggleReminders,
                                    activeColor: Colors.white,
                                    activeTrackColor: const Color(0xFFFFC09D),
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: Colors.grey[300],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              
                              Text('TODAY\'S RECORD', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 1.0)),
                              const SizedBox(height: 16),
                              
                              _buildRecordItem('10:30 AM', '300 ml', 'Glass of water'),
                              const SizedBox(height: 12),
                              _buildRecordItem('08:00 AM', '250 ml', 'Morning tea', isTea: true),
                              const SizedBox(height: 12),
                              _buildRecordItem('07:00 AM', '250 ml', 'Wake up water'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(String time, String amount, String desc, {bool isTea = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: (isTea ? const Color(0xFFFFCACB) : const Color(0xFFFFC09D)).withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                child: Icon(isTea ? Icons.emoji_food_beverage : Icons.water_drop, color: isTea ? const Color(0xFFFFCACB) : const Color(0xFFFFC09D)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(amount, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  Text(desc, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          Text(time, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

// ---- Custom Painters ----
class _HydrationRingTrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFC09D).withOpacity(0.1)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(size.width/2, size.height/2), size.width/2, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HydrationRingProgressPainter extends CustomPainter {
  final double progress;
  _HydrationRingProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: Offset(size.width/2, size.height/2), radius: size.width/2);
    final paint = Paint()
      ..color = const Color(0xFFFFC09D)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RemindersRingTrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(size.width/2, size.height/2), 100, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RemindersRingProgressPainter extends CustomPainter {
  final double progress;
  _RemindersRingProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: Offset(size.width/2, size.height/2), radius: 100);
    final gradient = const LinearGradient(colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)]).createShader(rect);
    final paint = Paint()
      ..shader = gradient
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
