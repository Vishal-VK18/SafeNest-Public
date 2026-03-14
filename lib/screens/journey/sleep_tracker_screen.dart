// lib/screens/journey/sleep_tracker_screen.dart
//
// SafeNest Sleep Tracker — UI matches design at:
//   C:\SafeNest app ui\Safenest blush ui\sleep_tracker\code.html
//
// Features:
//  • Night-sky circle with moon icon + live sleep timer
//  • Start / Pause / Stop tracking buttons
//  • Morning Insight + Nesting Tip cards
//  • Weekly Rhythm bar chart (last 7 days)
//  • Wind Down Reminder toggle + time picker
//  • All data persisted via SleepTrackerNotifier + StorageService

import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/route_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/sleep_session.dart';
import '../../models/sleep_tracker_model.dart' as old_sleep;
import '../../providers/providers.dart';
import '../../widgets/safe_nest_bottom_navigation.dart';


// ── Blush palette ──────────────────────────────────────────────────────────────
const _peach    = Color(0xFFFFC09D);
const _blush    = Color(0xFFFFCACB);
const _dark     = Color(0xFF181818);
const _muted    = Color(0xFF6F6F6F);
const _coral    = Color(0xFFF4A38C);
const _nightBg  = Color(0xFF2D3047);
const _nightBg2 = Color(0xFF434870);

class SleepTrackerScreen extends ConsumerStatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  ConsumerState<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends ConsumerState<SleepTrackerScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final sleepState = ref.watch(sleepTrackerProvider);
    final notifier = ref.read(sleepTrackerProvider.notifier);
    
    final isTracking = sleepState.isTracking;
    final lastSession = sleepState.lastSession;
    final activeSession = sleepState.activeSession;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: const SafeNestBottomNavigation(),

      body: Stack(

        children: [
          // ── Blush gradient background ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_peach, _blush],
                ),
              ),
            ),
          ),
          // ── Soft white overlay ──
          Positioned.fill(
            child: Container(color: const Color(0xFFFFFDFB).withValues(alpha: 0.3)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),

              child: Column(
                children: [
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _circleBtn(Icons.arrow_back, 20, () {
                          debugPrint('[SafeNest Nav] Sleep Tracker back button tapped');
                          Navigator.pop(context);
                        }),
                        Text(
                          'Rest & Recovery',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: _dark,
                          ),
                        ),
                        _circleBtn(Icons.notifications_none, 22, () {}),
                      ],
                    ),
                  ),

                  // ── Night-sky circle ──
                  _buildNightSkyCircle(
                    isTracking: isTracking,
                    isPaused: false, // Paused removed as per user spec
                    isIdle: !isTracking,
                    currentDuration: sleepState.elapsed,
                    lastSession: lastSession,
                  ),

                  const SizedBox(height: 16),

                  // ── Status tags ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _tag(isTracking
                          ? 'Tracking… ${ref.read(sleepTrackerProvider.notifier).formattedElapsed}'
                          : lastSession != null
                              ? 'Quality: ${lastSession.qualityFromDuration}'
                              : 'Ready to track'),
                      if (isTracking) ...[
                        const SizedBox(width: 8),
                        _tag('Tap Stop to save'),
                      ] else if (lastSession != null) ...[
                        const SizedBox(width: 8),
                        _tag('Feeling: Refreshed'),
                      ],
                    ],
                  ),
                  
                  if (sleepState.isSaving) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Saving to cloud...',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFE9A48E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Control buttons ──
                  _buildControls(
                    isIdle: !isTracking,
                    isTracking: isTracking,
                    isPaused: false,
                    notifier: notifier,
                  ),

                  const SizedBox(height: 32),

                  // ── Insights card ──
                  if (lastSession != null) ...[
                    _buildInsightsCard(lastSession!),
                    const SizedBox(height: 24),
                    // ── Sleep stages breakdown ──
                    _buildStagesCard(lastSession!),
                    const SizedBox(height: 24),
                  ],

                  // ── Weekly Rhythm ──
                  _buildWeeklyRhythm(sleepState.history),
                  const SizedBox(height: 24),

                  // ── Wind Down Reminder ──
                  _buildReminderCard(context, sleepState.reminder, notifier),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Night-sky circle ─────────────────────────────────────────────────────────
  Widget _buildNightSkyCircle({
    required bool isTracking,
    required bool isPaused,
    required bool isIdle,
    required Duration currentDuration,
    required SleepSession? lastSession,
  }) {
    String mainText;
    String subText;

    if (isTracking) {
      mainText = _formatDuration(currentDuration);
      subText  = 'Tracking your sleep…';
    } else if (isPaused) {
      mainText = _formatDuration(currentDuration);
      subText  = 'Sleep tracking paused';
    } else if (lastSession != null) {
      mainText = 'Your rest was deep\nand restorative';
      subText  = 'You slept for ${lastSession.formattedDuration}';
    } else {
      mainText = 'Ready to track\nyour sleep';
      subText  = 'Tap Start Sleep to begin';
    }

    return Container(
      width: 272,
      height: 272,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_nightBg, _nightBg2],
        ),
        boxShadow: [
          BoxShadow(
            color: _nightBg2.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Border rings
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1), width: 2),
              ),
            ),
          ),
          Positioned.fill(
            child: ClipOval(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border(
                    top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.4), width: 2),
                    right: BorderSide(
                        color: Colors.white.withValues(alpha: 0.4), width: 2),
                  ),
                ),
              ),
            ),
          ),
          // Stars
          ..._stars(),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bedtime, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                Text(
                  mainText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: isTracking || isPaused ? 22 : 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subText,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _stars() => [
    _star(top: 36, left: 72, size: 4),
    _star(top: 56, right: 60, size: 6),
    _star(bottom: 72, left: 44, size: 4),
    _star(top: 88, left: 132, size: 8, blur: true),
    _star(bottom: 52, right: 92, size: 4),
  ];

  Widget _star({
    double? top, double? bottom, double? left, double? right,
    double size = 4, bool blur = false,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: blur ? 0.4 : 0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // ── Controls ─────────────────────────────────────────────────────────────────
  Widget _buildControls({
    required bool isIdle,
    required bool isTracking,
    required bool isPaused,
    required SleepTrackerNotifier notifier,
  }) {
    if (isIdle) {
      return _primaryBtn(
        label: 'START SLEEP',
        icon: Icons.nightlight_round,
        onTap: notifier.startSleep,
      );
    }

    return Center(
      child: SizedBox(
        width: 200,
        child: _primaryBtn(
          label: 'STOP SLEEP',
          icon: Icons.stop_rounded,
          color: const Color(0xFFE68C6C), // Deep peach for active state
          onTap: () async {
            await notifier.stopSleep();
          },
        ),
      ),
    );
  }

  // ── Morning insights card ─────────────────────────────────────────────────────
  Widget _buildInsightsCard(SleepSession session) {
    final deepH = (session.durationMinutes ?? 0) * 0.45 / 60.0;
    return _glassCard(
      child: Column(
        children: [
          _insightRow(
            icon: Icons.auto_awesome,
            iconColor: _coral,
            title: 'Morning Insight',
            body:
                'Your body recovered beautifully last night with ${deepH.toStringAsFixed(1)} hours of deep sleep. This is perfect for supporting your energy levels today.',
          ),
          Divider(color: Colors.black.withValues(alpha: 0.05), height: 24),
          _insightRow(
            icon: Icons.lightbulb_outline,
            iconColor: _nightBg2,
            title: 'Nesting Tip',
            body:
                'Try a gentle 10-minute stretching routine before bed tonight to maintain this lovely rest cycle.',
          ),
        ],
      ),
    );
  }

  Widget _insightRow(
      {required IconData icon,
      required Color iconColor,
      required String title,
      required String body}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _dark)),
              const SizedBox(height: 4),
              Text(body,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: _muted, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Sleep stages card ─────────────────────────────────────────────────────────
  Widget _buildStagesCard(SleepSession session) {
    final total = session.durationMinutes ?? 0;
    if (total == 0) return const SizedBox.shrink();
    const deepFrac = 0.45;
    const lightFrac = 0.55;

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SLEEP STAGES',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: _muted)),
          const SizedBox(height: 16),
          // Segmented bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Flexible(
                  flex: (deepFrac * 100).round(),
                  child: Container(
                      height: 40, color: const Color(0xFFE9A48E)), // Accent Peach (Deep)
                ),
                Flexible(
                  flex: (lightFrac * 100).round(),
                  child: Container(
                      height: 40, color: const Color(0xFFF5C7B8)), // Light Peach (Light)
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendItem('Deep  ${(total * 0.45).round()}m',
                  const Color(0xFFE9A48E)),
              _legendItem('Light  ${(total * 0.55).round()}m',
                  const Color(0xFFF5C7B8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) => Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF555555))),
        ],
      );

  // ── Weekly Rhythm ─────────────────────────────────────────────────────────────
  Widget _buildWeeklyRhythm(List<SleepSession> history) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now  = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const maxBarHeight = 80.0;
    const recommended = 8.0;

    // Build a map: day-of-week → longest session that day
    final Map<int, double> hoursMap = {};
    for (final s in history) {
      final d = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      final offset = today.difference(d).inDays;
      if (offset < 0 || offset > 6) continue;
      // weekday: 1=Mon … 7=Sun; map to 0-based
      final idx = (s.startTime.weekday - 1) % 7;
      final h = (s.durationMinutes ?? 0) / 60.0;
      hoursMap[idx] = (hoursMap[idx] ?? 0).clamp(0, h + (hoursMap[idx] ?? 0));
    }

    // Today's weekday index
    final todayIdx = (now.weekday - 1) % 7;
    final bestIdx  = hoursMap.isEmpty
        ? null
        : hoursMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Weekly Rhythm',
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w600, color: _dark)),
        const SizedBox(height: 12),
        _glassCard(
          child: Column(
            children: [
              SizedBox(
                height: maxBarHeight + 32,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final hours = hoursMap[i] ?? 0;
                    final frac = (hours / recommended).clamp(0.0, 1.0);
                    final barH = maxBarHeight * (frac > 0 ? frac : 0.15);
                    final isBest   = bestIdx == i;
                    final isToday  = i == todayIdx;
                    final hasData  = frac > 0;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          width: 36,
                          height: barH,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            color: hasData
                                ? _coral
                                : const Color(0xFFEFE6E1),
                            border: isToday
                                ? Border.all(
                                    color: Colors.white, width: 2)
                                : null,
                            boxShadow: isBest
                                ? [
                                    BoxShadow(
                                        color: _coral.withOpacity(
                                            0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4)),
                                  ]
                                : null,
                          ),
                          child: hasData
                              ? const Center(
                                  child: Icon(Icons.check,
                                      color: Colors.white, size: 14))
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          days[i],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isToday ? _dark : _muted,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                history.isEmpty
                    ? 'Start tracking to see your weekly rhythm!'
                    : bestIdx != null
                        ? '${_dayName(bestIdx)} is your most restful day so far!'
                        : '',
                style: GoogleFonts.inter(
                    fontSize: 12, color: _muted, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _dayName(int i) {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[i % 7];
  }

  // ── Wind Down Reminder ────────────────────────────────────────────────────────
  Widget _buildReminderCard(
    BuildContext context,
    SleepReminderSettings reminder,
    SleepTrackerNotifier notifier,
  ) {
    final t = reminder.reminderTime ?? DateTime(2024, 1, 1, 22, 0);
    final isPm = t.hour >= 12;
    final displayHour = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final timeStr = '$displayHour:${t.minute.toString().padLeft(2, '0')} ${isPm ? 'PM' : 'AM'}';

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active,
                      color: _coral, size: 20),
                  const SizedBox(width: 8),
                  Text('Wind Down Reminder',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _dark)),
                ],
              ),
              Switch.adaptive(
                value: reminder.enabled,
                activeThumbColor: Colors.white,
                activeTrackColor: _coral,
                onChanged: (v) => notifier.setReminderEnabled(v),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reminder.enabled
                ? "We'll nudge you to start relaxing at $timeStr for a peaceful night."
                : "Enable the reminder to get a daily bedtime nudge.",
            style: GoogleFonts.inter(fontSize: 13, color: _muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: reminder.reminderTime != null 
                    ? TimeOfDay.fromDateTime(reminder.reminderTime!) 
                    : const TimeOfDay(hour: 22, minute: 0),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(alwaysUse24HourFormat: false),
                  child: child!,
                ),
              );
              if (picked != null) notifier.setReminderTime(picked);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bedtime Routine',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _dark)),
                  Row(
                    children: [
                      Text(timeStr,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _coral,
                              letterSpacing: 0.5)),
                      const SizedBox(width: 8),
                      Icon(Icons.edit_outlined, size: 16, color: _muted),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────────
  Widget _glassCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(28),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: _coral.withValues(alpha: 0.1),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      );

  Widget _tag(String text) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w500, color: _dark)),
      );

  Widget _circleBtn(IconData icon, double size, VoidCallback onTap) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (icon == Icons.arrow_back || icon == Icons.arrow_back_ios_new) {
            debugPrint('[SafeNest Nav] ← Back tapped: SleepTrackerScreen');
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
          } else {
            onTap();
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
          child: Icon(
            icon == Icons.arrow_back ? Icons.arrow_back_ios_new : icon,
            size: icon == Icons.arrow_back ? 18 : size,
            color: _dark,
          ),
        ),
      );

  Widget _primaryBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color color = _coral,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.2)),
            ],
          ),
        ),
      );

  Widget _outlineBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _coral.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _coral, size: 20),
              const SizedBox(width: 10),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _coral,
                      letterSpacing: 1.2)),
            ],
          ),
        ),
      );
}
