import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/log_entry.dart';
import '../../core/models/log_parameter.dart';
import '../../core/providers/logs_provider.dart';
import '../../utils/app_theme.dart';
import '../../core/constants/route_constants.dart';

class LogsDetailScreen extends ConsumerStatefulWidget {
  final LogParameter parameter;
  const LogsDetailScreen({super.key, required this.parameter});

  @override
  ConsumerState<LogsDetailScreen> createState() => _LogsDetailScreenState();
}

class _LogsDetailScreenState extends ConsumerState<LogsDetailScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(logsProvider(widget.parameter).notifier).fetchLogs();
    });
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _applyFilter() {
    ref.read(logsProvider(widget.parameter).notifier).fetchLogs(
          startDate: _startDate,
          endDate: _endDate,
        );
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    ref.read(logsProvider(widget.parameter).notifier).clearFilter();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logsProvider(widget.parameter));

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
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
                _buildHeader(context),
                Expanded(
                  child: state.isLoading
                      ? _buildShimmerList()
                      : state.error != null
                          ? _buildErrorView(state.error!)
                          : _buildContent(state),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              debugPrint('[SafeNest Nav] ← Back tapped: LogsDetailScreen');
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.parameter.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181818),
                  ),
                ),
                Text(
                  'Full History from Firebase',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF181818).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LogsState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        children: [
          _buildSummaryCard(state),
          const SizedBox(height: 16),
          _buildDateFilterRow(),
          const SizedBox(height: 24),
          if (widget.parameter != LogParameter.fallDetection) ...[
            _buildChartSection(state),
            const SizedBox(height: 24),
          ],
          _buildLogsList(state),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(LogsState state) {
    if (state.entries.isEmpty) return const SizedBox.shrink();

    final values = state.entries.map((e) => double.tryParse(e.value.toString()) ?? 0.0).toList();
    if (values.isEmpty && widget.parameter != LogParameter.fallDetection) return const SizedBox.shrink();

    if (widget.parameter == LogParameter.fallDetection) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8FD1B4).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security, color: Color(0xFF3DBB7C)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STATUS: OPERATIONAL',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3DBB7C),
                    ),
                  ),
                  Text(
                    '${state.entries.length} events detected',
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF181818)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final latestValue = state.entries.first.value;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final avgVal = values.reduce((a, b) => a + b) / values.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('LATEST', latestValue.toString(), widget.parameter.unit),
              _buildStatItem('AVERAGE', avgVal.toStringAsFixed(1), widget.parameter.unit),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('HIGHEST', maxVal.toStringAsFixed(1), widget.parameter.unit),
              _buildStatItem('LOWEST', minVal.toStringAsFixed(1), widget.parameter.unit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: const Color(0xFF181818).withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF181818),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181818).withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateFilterRow() {
    final df = DateFormat('yyyy-MM-dd');
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _selectStartDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4E4DE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _startDate == null ? 'From' : df.format(_startDate!),
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF181818)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _selectEndDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4E4DE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _endDate == null ? 'To' : df.format(_endDate!),
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF181818)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _clearFilter,
              child: Text(
                'Clear',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE9A48E),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _applyFilter,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE9A48E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: Text('Apply Filter', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection(LogsState state) {
    if (state.entries.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TREND CHART',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: const Color(0xFF181818).withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: TrendLinePainter(
                entries: state.entries.reversed.take(7).toList(),
                accentColor: widget.parameter.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(LogsState state) {
    if (state.entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: const Color(0xFF181818).withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No logs found for this period',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181818).withOpacity(0.4),
              ),
            ),
            Text(
              'Data will appear here once recorded',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF181818).withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = state.entries[index];
        return _buildLogItem(entry);
      },
    );
  }

  Widget _buildLogItem(LogEntry entry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.date,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181818),
                  ),
                ),
                Text(
                  entry.timestamp,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF181818).withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Text(widget.parameter.iconAsset, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.parameter.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF181818).withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.value.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: widget.parameter.accentColor,
                  ),
                ),
                Text(
                  entry.unit,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF181818).withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildErrorView(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE9A48E), size: 48),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: const Color(0xFF181818)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(logsProvider(widget.parameter).notifier).fetchLogs(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class TrendLinePainter extends CustomPainter {
  final List<LogEntry> entries;
  final Color accentColor;

  TrendLinePainter({required this.entries, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final values = entries.map((e) => double.tryParse(e.value.toString()) ?? 0.0).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (values.length - 1);
    
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - ((values[i] - minVal) / range * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      
      if (i == values.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    // Gradient fill
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accentColor.withOpacity(0.2), accentColor.withOpacity(0.0)],
        ).createShader(Rect.fromLTRB(0, 0, size.width, size.height)),
    );

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF181818).withOpacity(0.05)
      ..strokeWidth = 1;
    
    for (int i = 1; i < 4; i++) {
      final gy = size.height / 4 * i;
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), gridPaint);
    }

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = accentColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Latest dot
    final lastX = (values.length - 1) * stepX;
    final lastY = size.height - ((values.last - minVal) / range * size.height);
    canvas.drawCircle(Offset(lastX, lastY), 5, Paint()..color = accentColor);
    canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant TrendLinePainter oldDelegate) => true;
}
