import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/temperature_entry.dart';

class TemperatureLogPage extends ConsumerStatefulWidget {
  const TemperatureLogPage({super.key});

  @override
  ConsumerState<TemperatureLogPage> createState() => _TemperatureLogPageState();
}

class _TemperatureLogPageState extends ConsumerState<TemperatureLogPage> {
  late DateTime fromDate;
  late DateTime toDate;

  @override
  void initState() {
    super.initState();
    toDate = DateTime.now();
    fromDate = DateTime.now().subtract(const Duration(days: 7));
  }

  List<TemperatureEntry> _filterEntries(List<TemperatureEntry> allEntries) {
    final filtered = allEntries.where((entry) {
      final date = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
      final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
      final end = DateTime(toDate.year, toDate.month, toDate.day);

      return date.isAtSameMomentAs(start) ||
          date.isAtSameMomentAs(end) ||
          (date.isAfter(start) && date.isBefore(end));
    }).toList();

    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate,
      firstDate: DateTime(2024),
      lastDate: toDate,
      builder: (context, child) => _buildDatePickerTheme(child!),
    );
    if (picked != null && picked != fromDate) {
      setState(() => fromDate = picked);
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: toDate,
      firstDate: fromDate,
      lastDate: DateTime.now(),
      builder: (context, child) => _buildDatePickerTheme(child!),
    );
    if (picked != null && picked != toDate) {
      setState(() => toDate = picked);
    }
  }

  Widget _buildDatePickerTheme(Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          onSurface: Colors.black,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = ref.watch(temperatureLogProvider);
    final filteredEntries = _filterEntries(allEntries);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Temperature Log',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1C1C1E)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildRangeSelector(),
            Expanded(
              child: filteredEntries.isEmpty ? _buildEmptyState() : _buildLogList(filteredEntries),
            ),
            _buildExportButton(filteredEntries),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: _buildDateTile("FROM", fromDate, () => _selectFromDate(context))),
          const SizedBox(width: 16),
          Expanded(child: _buildDateTile("TO", toDate, () => _selectToDate(context))),
        ],
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.softGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.thermostat_outlined, size: 64, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No data for this range',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(List<TemperatureEntry> entries) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildLogCard(entries[index]),
    );
  }

  Widget _buildLogCard(TemperatureEntry entry) {
    final bool isElevated = entry.value >= 37.5;
    const Color coral = Color(0xFFF08080);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isElevated ? coral.withOpacity(0.05) : AppColors.softGray,
        borderRadius: BorderRadius.circular(20),
        border: isElevated ? Border.all(color: coral.withOpacity(0.2), width: 1) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isElevated ? coral.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.thermostat_rounded, color: isElevated ? coral : AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.value.toStringAsFixed(1)}°C',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C1C1E),
                  ),
                ),
                Text(
                  DateFormat('MMMM dd, hh:mm a').format(entry.timestamp),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isElevated ? coral.withOpacity(0.15) : AppColors.statusGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isElevated ? "ELEVATED" : "NORMAL",
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isElevated ? coral : AppColors.statusGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(List<TemperatureEntry> filteredEntries) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${filteredEntries.length} entries exported')),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.share_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  "EXPORT DATA",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
