import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
          primary: Color(0xFF1F3D3D), // Safenest Dark Teal
          onPrimary: Colors.white,
          onSurface: Color(0xFF181818),
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                _buildRangeSelector(),
                Expanded(
                  child: filteredEntries.isEmpty
                      ? _buildEmptyState()
                      : _buildLogList(filteredEntries),
                ),
                _buildExportButton(filteredEntries),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.centerLeft,
              child: const Icon(Icons.arrow_back, color: Color(0xFF181818), size: 24),
            ),
          ),
          Text(
            'Temperature Log',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: true ? FontWeight.bold : FontWeight.w700,
              color: const Color(0xFF181818),
            ),
          ),
          const SizedBox(width: 40), // Balance the flex
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 25,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF181818).withOpacity(0.4),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF181818),
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
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE5DA),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.device_thermostat, size: 60, color: Color(0xFFFFC09D)),
          ),
          const SizedBox(height: 24),
          Text(
            'No data for this range',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9A9A9A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(List<TemperatureEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: entries.length,
      itemBuilder: (context, index) => _buildLogCard(entries[index]),
    );
  }

  Widget _buildLogCard(TemperatureEntry entry) {
    final bool isElevated = entry.value >= 37.5;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isElevated ? const Color(0xFFFF9E80).withOpacity(0.2) : const Color(0xFFFFE5DA),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.device_thermostat, color: isElevated ? const Color(0xFFFF9E80) : const Color(0xFF181818), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.value.toStringAsFixed(1)}°C',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF181818),
                  ),
                ),
                Text(
                  DateFormat('MMMM dd, hh:mm a').format(entry.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B6B6B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isElevated ? const Color(0xFFFF9E80).withOpacity(0.2) : Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isElevated ? "ELEVATED" : "NORMAL",
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: isElevated ? const Color(0xFFFF9E80) : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(List<TemperatureEntry> filteredEntries) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${filteredEntries.length} entries exported')),
          );
        },
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1F3D3D),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.share, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                "EXPORT DATA",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
