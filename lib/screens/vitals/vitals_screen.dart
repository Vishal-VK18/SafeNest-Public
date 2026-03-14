// lib/screens/vitals/vitals_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/providers.dart';
import '../../core/constants/route_constants.dart';
import '../../models/safety_event_model.dart';

// ─── Blush palette ────────────────────────────────────────────────────────────
const _coral     = Color(0xFFE9A48E);
const _dark      = Color(0xFF181818);
const _cream     = Color(0xFFF8EEE9);
const _inputBg   = Color(0xFFFAF3EF);
const _green     = Color(0xFF3DBB7C);
const _redAccent = Color(0xFFE57373);

class VitalsScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const VitalsScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends ConsumerState<VitalsScreen> {
  late int _selectedTab;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)],
                ),
              ),
            ),
          ),
          // ── Soft white diffusion overlay ──
          Positioned.fill(
            child: Container(color: const Color.fromRGBO(255, 253, 251, 0.4)),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          debugPrint('[SafeNest Nav] ← Back tapped: VitalsScreen');
                          debugPrint('[SafeNest Nav] canPop: ${Navigator.of(context).canPop()}');
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else if (Navigator.of(context, rootNavigator: true).canPop()) {
                            Navigator.of(context, rootNavigator: true).pop();
                          } else {
                            Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                              RouteConstants.dashboard,
                              (route) => false,
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
                      Expanded(
                        child: Text(
                          _tabTitle(_selectedTab),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF181818),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                // ── Segmented Control ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      children: [
                        _tab(0, 'Heart Rate'),
                        _tab(1, 'Temperature'),
                        _tab(2, 'Fall Detection'),
                      ],
                    ),
                  ),
                ),

                // ── Content ──
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      SingleChildScrollView(
                        controller: _selectedTab == 0 ? _scrollController : null,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        child: _HeartRateTab(ref: ref),
                      ),
                      SingleChildScrollView(
                        controller: _selectedTab == 1 ? _scrollController : null,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        child: _TemperatureTab(ref: ref),
                      ),
                      const SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        child: _FallDetectionTab(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _tabTitle(int tab) {
    switch (tab) {
      case 0: return 'Heart Rate Tracker';
      case 1: return 'Temperature Tracker';
      default: return 'Fall Detection';
    }
  }

  Widget _tab(int idx, String label) {
    final active = _selectedTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          debugPrint('[SafeNest Nav] Vitals tab switched to: $idx ($label)');
          setState(() => _selectedTab = idx);
          _scrollController.jumpTo(0);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? _dark : _dark.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Heart Rate Tab
// ─────────────────────────────────────────────────────────────────────────────
class _HeartRateTab extends StatelessWidget {
  final WidgetRef ref;
  const _HeartRateTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(healthDataProvider);
    final hasData = health.receivedAt.year > 2000;
    final bpm = hasData ? health.heartRate : 78;
    final isNormal = health.isHeartRateNormal;

    return Column(
      children: [
        // ── Hero metric card ──
        _MetricHeroCard(
          label: 'AVERAGE HEART RATE',
          subLabel: 'Based on today\'s measurements',
          value: '$bpm',
          unit: 'BPM',
          statusColor: isNormal ? _green : _redAccent,
          statusText: isNormal ? 'Normal' : 'Elevated',
          decoration: const Icon(Icons.favorite, color: Color(0xFFE9A48E), size: 80),
        ),
        const SizedBox(height: 16),

        // ── Chart card ──
        _ChartCard(
          title: 'Heart Rate Over Time',
          yLabels: const ['120', '110', '100', '90', '80', '70', '60', '50'],
          xLabels: const ['00:00', '03:00', '06:00', '09:00', '12:00', '15:00', '18:00', '21:00'],
          painter: _HeartRateChartPainter(),
        ),
        const SizedBox(height: 16),

        // ── Recent readings ──
        _SectionHeader(title: 'RECENT READINGS'),
        const SizedBox(height: 10),
        _ReadingItem(time: '09:12 AM', value: '$bpm BPM', status: 'Normal', ok: true),
        const SizedBox(height: 8),
        _ReadingItem(time: '07:30 AM', value: '72 BPM', status: 'Resting', ok: true),
        const SizedBox(height: 8),
        _ReadingItem(time: '06:00 AM', value: '68 BPM', status: 'Resting', ok: true),
        const SizedBox(height: 20),

        // ── Full log button ──
        _ActionButton(
          label: 'VIEW FULL LOG',
          icon: Icons.list_alt_rounded,
          onTap: () => Navigator.pushNamed(context, RouteConstants.heartRateLog),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Temperature Tab
// ─────────────────────────────────────────────────────────────────────────────
class _TemperatureTab extends StatelessWidget {
  final WidgetRef ref;
  const _TemperatureTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(healthDataProvider);
    final tempLog = ref.watch(temperatureLogProvider);
    final hasData = health.receivedAt.year > 2000;
    final temp = hasData ? health.temperature : 0.0;
    final isNormal = health.isTemperatureNormal;

    // Build chart data from real log — last 8 entries reversed (oldest→newest)
    final chartData = tempLog.isEmpty
        ? <double>[]
        : tempLog.reversed.take(8).toList().map((e) => e.value).toList();

    // Recent readings — last 3 entries
    final recentReadings = tempLog.take(3).toList();

    // Average from log
    final avgTemp = tempLog.isEmpty
        ? temp
        : tempLog.map((e) => e.value).reduce((a, b) => a + b) / tempLog.length;

    return Column(
      children: [
        // ── Hero metric card ──
        _MetricHeroCard(
          label: 'AVERAGE BODY TEMPERATURE',
          subLabel: 'Based on ${tempLog.length} measurements',
          value: temp > 0 ? temp.toStringAsFixed(1) : '—',
          unit: '°C',
          statusColor: temp == 0 ? Colors.grey : (isNormal ? _green : _redAccent),
          statusText: temp == 0 ? 'No Data' : (isNormal ? 'Normal' : 'Elevated'),
          decoration: const Icon(Icons.device_thermostat_outlined, color: Color(0xFFE9A48E), size: 80),
        ),
        const SizedBox(height: 16),

        // ── Chart card — real data ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TODAY\'S DATA', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.grey[400])),
              const SizedBox(height: 4),
              Text('Temperature Over Time', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
              const SizedBox(height: 20),
              if (chartData.isEmpty)
                SizedBox(
                  height: 180,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.show_chart, color: Colors.grey[300], size: 48),
                        const SizedBox(height: 12),
                        Text('No chart data yet', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400])),
                        Text('Connect the band to see live data', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400])),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 180,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: ['34.0', '33.5', '33.0', '32.5', '32.0', '31.5', '31.0', '30.5', '30.0']
                            .map((l) => Text(l, style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[400])))
                            .toList(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRect(
                          child: CustomPaint(
                            painter: _TemperatureChartPainter(data: chartData),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              if (chartData.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: tempLog.reversed.take(chartData.length).toList().map((e) {
                      return Text(
                        '${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[400]),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Fever threshold notice ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _redAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: _redAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'High temp threshold: 33.0°C — contact your doctor if exceeded.',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: _redAccent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Recent readings — real data ──
        _SectionHeader(title: 'RECENT READINGS'),
        const SizedBox(height: 10),
        if (recentReadings.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No readings yet — connect the band',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
              ),
            ),
          )
        else
          ...recentReadings.map((entry) {
            final isElevated = entry.value >= 37.5;
            final timeStr = '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ReadingItem(
                time: timeStr,
                value: '${entry.value.toStringAsFixed(1)}°C',
                status: isElevated ? 'Elevated' : 'Normal',
                ok: !isElevated,
              ),
            );
          }),
        const SizedBox(height: 20),

        // ── Full log button ──
        _ActionButton(
          label: 'VIEW FULL LOG',
          icon: Icons.list_alt_rounded,
          onTap: () => Navigator.pushNamed(context, RouteConstants.temperatureLog),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fall Detection Tab
// ─────────────────────────────────────────────────────────────────────────────
class _FallDetectionTab extends ConsumerWidget {
  const _FallDetectionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthDataProvider);
    final hasFall = health.fallDetected;
    final safetyEvents = ref.watch(safetyHistoryProvider);

    // Real fall events from history
    final fallEvents = safetyEvents
        .where((e) => e.type == SafetyEventType.fall)
        .toList();

    // Today's falls
    final today = DateTime.now();
    final todayFalls = fallEvents.where((e) =>
        e.timestamp.year == today.year &&
        e.timestamp.month == today.month &&
        e.timestamp.day == today.day).toList();

    return Column(
      children: [
        // ── Status card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CURRENT STATUS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: const Color(0xFF6F6F6F))),
                  const SizedBox(height: 4),
                  Text('Monitoring active · Last checked 2s ago', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6F6F6F))),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        hasFall ? 'Alert' : 'Safe',
                        style: GoogleFonts.inter(fontSize: 44, fontWeight: FontWeight.w800, color: _dark),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasFall ? _redAccent.withValues(alpha: 0.15) : _green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          hasFall ? '● Fall!' : '● Normal',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: hasFall ? _redAccent : _green),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Opacity(
                  opacity: 0.07,
                  child: Icon(Icons.personal_injury_outlined, size: 90, color: _dark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Stats row ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8))],
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
                      Text('DATE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.grey[400])),
                      Text(
                        _todayLabel(),
                        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: _dark),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _StatMini(
                    value: todayFalls.length.toString(),
                    label: 'Falls Today',
                    valueColor: todayFalls.isNotEmpty ? _redAccent : _dark,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatMini(value: '${fallEvents.length}', label: 'Total Events')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatMini(
                    value: todayFalls.isEmpty ? '100%' : '${(100 - (todayFalls.length * 10)).clamp(0, 100)}%',
                    label: 'Safe Time',
                    valueColor: _green,
                  )),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Fall event log ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FALL EVENT LOG', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.grey[400])),
              const SizedBox(height: 16),
              if (hasFall)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FallEventItem(
                    date: 'Today · Just now',
                    type: 'Fall Detected',
                    isAlert: true,
                  ),
                ),
              if (fallEvents.isEmpty && !hasFall)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_outline, color: _green, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text('No falls detected',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF6F6F6F))),
                        const SizedBox(height: 6),
                        Text('The wearable is actively monitoring.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6F6F6F))),
                      ],
                    ),
                  ),
                )
              else
                ...fallEvents.take(5).map((event) {
                  final months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
                  final t = event.timestamp;
                  final dateStr =
                      '${t.day} ${months[t.month - 1]} · ${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FallEventItem(
                      date: dateStr,
                      type: 'Fall Detected',
                      isAlert: true,
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Detection sensitivity ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('DETECTION SENSITIVITY', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.grey[400])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2C6B8).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text('Medium', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _coral)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Static progress bar representing "Medium" (50%)
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2C6B8).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)]),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Low', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[400])),
                  Text('High', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[400])),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Full log button ──
        _ActionButton(
          label: 'VIEW FULL LOG',
          icon: Icons.list_alt_rounded,
          onTap: () => Navigator.pushNamed(context, RouteConstants.fallEventLog),
        ),
      ],
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${now.day} ${months[now.month - 1]}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Components
// ─────────────────────────────────────────────────────────────────────────────
class _MetricHeroCard extends StatelessWidget {
  final String label;
  final String subLabel;
  final String value;
  final String unit;
  final Color statusColor;
  final String statusText;
  final Widget decoration;

  const _MetricHeroCard({
    required this.label,
    required this.subLabel,
    required this.value,
    required this.unit,
    required this.statusColor,
    required this.statusText,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: const Color(0xFF6F6F6F))),
              const SizedBox(height: 4),
              Text(subLabel, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6F6F6F))),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: GoogleFonts.inter(fontSize: 52, fontWeight: FontWeight.w800, color: _dark, letterSpacing: -2)),
                  const SizedBox(width: 6),
                  Text(unit, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF6F6F6F))),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  '● $statusText',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Opacity(opacity: 0.1, child: decoration),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final List<String> yLabels;
  final List<String> xLabels;
  final CustomPainter painter;

  const _ChartCard({
    required this.title,
    required this.yLabels,
    required this.xLabels,
    required this.painter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TODAY\'S DATA', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.grey[400])),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                // Y-axis labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: yLabels.map((l) => Text(l, style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[400]))).toList(),
                ),
                const SizedBox(width: 8),
                // Chart
                Expanded(
                  child: CustomPaint(painter: painter, size: const Size(double.infinity, 180)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // X-axis labels
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: xLabels.map((l) => Text(l, style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[400]))).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.grey[500])),
    );
  }
}

class _ReadingItem extends StatelessWidget {
  final String time;
  final String value;
  final String status;
  final bool ok;

  const _ReadingItem({required this.time, required this.value, required this.status, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (ok ? _green : _redAccent).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(ok ? Icons.check_circle_outline : Icons.warning_amber_rounded, color: ok ? _green : _redAccent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
                Text(status, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6F6F6F))),
              ],
            ),
          ),
          Text(time, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF6F6F6F))),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _StatMini({required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: valueColor ?? _dark)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.grey[400])),
        ],
      ),
    );
  }
}

class _FallEventItem extends StatelessWidget {
  final String date;
  final String type;
  final bool isAlert;

  const _FallEventItem({required this.date, required this.type, required this.isAlert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isAlert ? _coral : _green).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(isAlert ? Icons.warning_amber_rounded : Icons.check_rounded, color: isAlert ? _coral : _green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _dark)),
                Text(date, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isAlert ? _coral : _green).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              isAlert ? 'Alert Sent' : 'Resolved',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: isAlert ? _coral : _green),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart Painters
// ─────────────────────────────────────────────────────────────────────────────
class _HeartRateChartPainter extends CustomPainter {
  final List<double> data = const [72, 78, 75, 82, 88, 80, 85, 76];
  final double minVal = 50.0;
  final double maxVal = 120.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (int i = 0; i < 8; i++) {
      final y = (size.height / 7) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Threshold line at 100 BPM
    final threshPaint = Paint()
      ..color = _redAccent
      ..strokeWidth = 1.5;
    final threshY = ((maxVal - 100) / (maxVal - minVal)) * size.height;
    _drawDashedLine(canvas, Offset(0, threshY), Offset(size.width, threshY), threshPaint);

    final getX = (int i) => (size.width / (data.length - 1)) * i;
    final getY = (double v) => ((maxVal - v) / (maxVal - minVal)) * size.height;

    // Main line
    final linePaint = Paint()
      ..color = _dark
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.miter
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      i == 0 ? path.moveTo(getX(i), getY(data[i])) : path.lineTo(getX(i), getY(data[i]));
    }
    canvas.drawPath(path, linePaint);

    // Markers
    for (int i = 0; i < data.length; i++) {
      final highlight = i == 4;
      final circlePaint = Paint()..color = highlight ? _redAccent : _dark;
      canvas.drawCircle(Offset(getX(i), getY(data[i])), highlight ? 5 : 3.5, circlePaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double distance = (end - start).distance;
    double drawn = 0;
    final direction = (end - start) / distance;
    while (drawn < distance) {
      final dash = drawn + dashWidth < distance ? dashWidth : distance - drawn;
      canvas.drawLine(start + direction * drawn, start + direction * (drawn + dash), paint);
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TemperatureChartPainter extends CustomPainter {
  final List<double> data;
  final double minVal = 30.0;
  final double maxVal = 34.0;

  _TemperatureChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    // Clamp all values inside min/max so line never goes outside box
    final safeData = data.map((v) => v.clamp(minVal, maxVal)).toList();

    // Add padding so line never touches top/bottom edge
    const vPad = 10.0;
    final drawH = size.height - vPad * 2;

    final getX = (int i) => (size.width / (safeData.length - 1)) * i;
    final getY = (double v) => vPad + ((maxVal - v) / (maxVal - minVal)) * drawH;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (int i = 0; i < 6; i++) {
      final y = vPad + (drawH / 5) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Fever threshold at 33.0
    final threshPaint = Paint()
      ..color = _redAccent
      ..strokeWidth = 1.5;
    final threshY = getY(33.0);
    _drawDashedLine(canvas, Offset(0, threshY), Offset(size.width, threshY), threshPaint);

    // Main line — black, inside box
    final linePaint = Paint()
      ..color = _dark
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (int i = 0; i < safeData.length; i++) {
      final x = getX(i);
      final y = getY(safeData[i]);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, linePaint);

    // Markers
    for (int i = 0; i < safeData.length; i++) {
      final x = getX(i);
      final y = getY(safeData[i]);
      final isLast = i == safeData.length - 1;
      // Fill
      canvas.drawCircle(Offset(x, y), isLast ? 5 : 3.5,
          Paint()..color = isLast ? Colors.white : _dark);
      // Stroke
      canvas.drawCircle(
        Offset(x, y),
        isLast ? 5 : 3.5,
        Paint()
          ..color = isLast ? _redAccent : _dark
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double distance = (end - start).distance;
    double drawn = 0;
    final direction = (end - start) / distance;
    while (drawn < distance) {
      final dash = drawn + dashWidth < distance ? dashWidth : distance - drawn;
      canvas.drawLine(start + direction * drawn, start + direction * (drawn + dash), paint);
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
