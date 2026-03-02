// lib/screens/journey/hydration_tracker/hydration_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/hydration_model.dart';
import '../../../providers/providers.dart';
import '../../../services/hydration_reminder_service.dart';

class HydrationTrackerScreen extends ConsumerStatefulWidget {
  const HydrationTrackerScreen({super.key});

  @override
  ConsumerState<HydrationTrackerScreen> createState() =>
      _HydrationTrackerScreenState();
}

class _HydrationTrackerScreenState
    extends ConsumerState<HydrationTrackerScreen> {
  // Reminder service is a singleton — init lazily
  final _reminderSvc = HydrationReminderService.instance;

  @override
  void initState() {
    super.initState();
    // Initialise the notification plugin once
    _reminderSvc.init();
  }

  // ── Quick-add helpers ──────────────────────────────────────────────────────
  void _addWater(double liters) {
    ref.read(hydrationProvider.notifier).addEntry(liters);
  }

  // ── Custom amount dialog ───────────────────────────────────────────────────
  Future<void> _showCustomDialog() async {
    final ctrl = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Custom Amount',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF9B8AA4),
          ),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
          ],
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Enter amount in mL (e.g. 350)',
            hintStyle: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFFB5A7C4)),
            suffixText: 'mL',
            suffixStyle: GoogleFonts.inter(color: const Color(0xFF9B8AA4)),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide:
                  BorderSide(color: Color(0xFFC8B8DB), width: 2),
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.grey[500])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC8B8DB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final val = double.tryParse(ctrl.text.trim());
              Navigator.pop(ctx, val);
            },
            child: Text('Add',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      _addWater(result / 1000.0); // mL → L
    }
  }

  // ── Reminder toggle ────────────────────────────────────────────────────────
  Future<void> _onReminderToggle(bool enabled) async {
    ref
        .read(hydrationProvider.notifier)
        .setReminder(enabled: enabled);
    if (enabled) {
      final freq =
          ref.read(hydrationProvider).reminderFreqHours;
      await _reminderSvc.scheduleReminder(frequencyHours: freq);
    } else {
      await _reminderSvc.cancelReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hyd  = ref.watch(hydrationProvider);
    final preg = ref.watch(pregnancyProvider);
    final double goal =
        preg.pregnancyWeek <= 13 ? 2.5 : (preg.pregnancyWeek <= 26 ? 2.8 : 3.0);
    final fraction  = (hyd.intakeLiters / goal).clamp(0.0, 1.0);
    final remaining = (goal - hyd.intakeLiters).clamp(0.0, goal);
    final int percent = (fraction * 100).toInt();

    // Time-bucket amounts
    final morningL  = hyd.morningLiters;
    final afterL    = hyd.afternoonLiters;
    final eveningL  = hyd.eveningLiters;
    const maxBucketHeight = 112.0; // tallest bar at max intake (matches UI)
    const bucketMax = 1.2; // 1.2L per bucket = full bar

    double barHeight(double liters) =>
        (liters / bucketMax).clamp(0.0, 1.0) * maxBucketHeight;

    // Weekly average
    final avgL   = hyd.weeklyAverage;
    final avgTxt = avgL > 0 ? 'Avg: ${avgL.toStringAsFixed(1)}L' : 'Avg: --';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8FC),
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Container(
            margin: const EdgeInsets.all(8.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF9B8AA4)),
              iconSize: 20,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Hydration Tracker',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF9B8AA4),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              margin: const EdgeInsets.all(8.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon:
                    const Icon(Icons.settings, color: Color(0xFF9B8AA4)),
                iconSize: 20,
                // Part 4: navigate to Profile/Settings screen
                onPressed: () =>
                    Navigator.pushNamed(context, '/profile'),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
        child: Column(
          children: [
            // ── Progress Ring ────────────────────────────────────────────────
            Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 224,
                      height: 224,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC8B8DB).withOpacity(0.1),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        value: fraction,
                        strokeWidth: 16,
                        backgroundColor: const Color(0xFFE8DFF5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFC8B8DB)),
                      ),
                    ),
                    Container(
                      width: 192,
                      height: 192,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFAF8FC),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$percent%',
                            style: GoogleFonts.inter(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFC8B8DB),
                              letterSpacing: -1.0,
                            ),
                          ),
                          Text(
                            'Daily Goal',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFB5A7C4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${hyd.intakeLiters.toStringAsFixed(1)}L',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF9B8AA4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/ ${goal}L',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFB5A7C4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${remaining.toStringAsFixed(1)}L remaining',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFB5A7C4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8DFF5).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '${hyd.streakDays} Day Streak 🔥',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFC8B8DB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Quick Add ────────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Add',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9B8AA4),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAddButton(
                        icon: Icons.local_drink,
                        label: '250ml',
                        isFilled: true,
                        onTap: () => _addWater(0.25),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAddButton(
                        icon: Icons.water_drop,
                        label: '500ml',
                        isFilled: true,
                        onTap: () => _addWater(0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAddButton(
                        icon: Icons.wine_bar,
                        label: '1L',
                        isFilled: true,
                        onTap: () => _addWater(1.0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAddButton(
                        icon: Icons.add,
                        label: 'Custom',
                        isFilled: false,
                        onTap: _showCustomDialog,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Today's Intake (time-based, dynamic) ─────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: const Color(0xFFE8DFF5).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 4),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s Intake',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF9B8AA4),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFE8DFF5).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          avgTxt,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB5A7C4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildIntakeBar(
                        'Morning',
                        morningL,
                        maxBucketHeight,
                        barHeight(morningL) / maxBucketHeight,
                      ),
                      _buildIntakeBar(
                        'Afternoon',
                        afterL,
                        maxBucketHeight,
                        barHeight(afterL) / maxBucketHeight,
                      ),
                      _buildIntakeBar(
                        'Evening',
                        eveningL,
                        maxBucketHeight,
                        barHeight(eveningL) / maxBucketHeight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Weekly Trend ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: const Color(0xFFE8DFF5).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 4),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Trend',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9B8AA4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 128,
                    width: double.infinity,
                    child: CustomPaint(
                      painter:
                          _WeeklyTrendPainter(_buildWeeklyData(hyd)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:
                          ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                        return Text(
                          day,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB5A7C4),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Smart Reminder ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF9B8AA4),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9B8AA4).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Reminder',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Every ${hyd.reminderFreqHours} hour${hyd.reminderFreqHours > 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color:
                                  const Color(0xFFE8DFF5).withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: hyd.reminderEnabled,
                    onChanged: _onReminderToggle,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white.withOpacity(0.3),
                    inactiveThumbColor: Colors.white.withOpacity(0.8),
                    inactiveTrackColor: Colors.white.withOpacity(0.1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Status Card ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange[100]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hyd.intakeLiters < (goal * 0.4) &&
                              DateTime.now().hour >= 16
                          ? 'Possible dehydration risk. Drink 500ml now.'
                          : 'Hydration is on track. Keep sipping throughout the day!',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9B8AA4),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build 7-day data array from history (Mon→Sun, index 0=Mon) ────────────
  List<double> _buildWeeklyData(HydrationModel hyd) {
    final today  = DateTime.now();
    final result = List<double>.filled(7, 0.0);
    // Slot 6 = today
    result[today.weekday - 1] = hyd.intakeLiters;
    for (final entry in hyd.history.entries) {
      final d = DateTime.tryParse(entry.key);
      if (d == null) continue;
      final diff = today.difference(d).inDays;
      if (diff >= 1 && diff <= 6) {
        result[(today.weekday - 1 - diff + 7) % 7] = entry.value;
      }
    }
    return result;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildQuickAddButton({
    required IconData icon,
    required String label,
    required bool isFilled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:
              isFilled ? const Color(0xFFE8DFF5) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isFilled
              ? null
              : Border.all(color: const Color(0xFFE8DFF5), width: 2),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isFilled
                  ? const Color(0xFFC8B8DB)
                  : const Color(0xFFB5A7C4),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isFilled
                    ? const Color(0xFF9B8AA4)
                    : const Color(0xFFB5A7C4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntakeBar(
    String label,
    double liters,
    double maxHeight,
    double fillFraction,
  ) {
    final fillH = (fillFraction * maxHeight).clamp(0.0, maxHeight);
    final amtTxt = liters >= 1.0
        ? '${liters.toStringAsFixed(1)}L'
        : '${(liters * 1000).toStringAsFixed(0)}ml';

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 48,
          height: maxHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFE8DFF5),
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            width: 48,
            height: fillH,
            decoration: BoxDecoration(
              color: const Color(0xFFC8B8DB),
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB5A7C4),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          liters > 0 ? amtTxt : '0ml',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF9B8AA4),
          ),
        ),
      ],
    );
  }
}

// ─── Weekly Trend Painter ─────────────────────────────────────────────────────
class _WeeklyTrendPainter extends CustomPainter {
  final List<double> data; // 7 values (Mon→Sun)
  final double maxVal;

  _WeeklyTrendPainter(this.data)
      : maxVal = data.reduce((a, b) => a > b ? a : b).clamp(0.1, 4.0);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFC8B8DB)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = const Color(0xFFC8B8DB).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final dashPaint = Paint()
      ..color = const Color(0xFFB5A7C4).withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    void drawDashedLine(double y) {
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset(x + 5, y), dashPaint);
        x += 10;
      }
    }

    drawDashedLine(0);
    drawDashedLine(size.height * 0.33);
    drawDashedLine(size.height * 0.66);
    drawDashedLine(size.height);

    // Build the trend path from actual data
    final stepWidth = size.width / (data.length - 1);
    final points = List.generate(data.length, (i) {
      final x = i * stepWidth;
      final y = size.height - (data[i] / maxVal) * size.height;
      return Offset(x, y);
    });

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpX = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw data points
    final dotPaint = Paint()
      ..color = const Color(0xFFC8B8DB)
      ..style = PaintingStyle.fill;
    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyTrendPainter old) =>
      old.data != data;
}
