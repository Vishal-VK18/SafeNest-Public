// lib/screens/logs/heart_rate_log_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';

class HeartRateEntry {
  final int bpm;
  final DateTime timestamp;

  HeartRateEntry({required this.bpm, required this.timestamp});
}

class HeartRateLogScreen extends StatefulWidget {
  const HeartRateLogScreen({super.key});

  @override
  State<HeartRateLogScreen> createState() => _HeartRateLogScreenState();
}

class _HeartRateLogScreenState extends State<HeartRateLogScreen> {
  late DateTime fromDate;
  late DateTime toDate;
  late List<HeartRateEntry> allEntries;
  late List<HeartRateEntry> filteredEntries;

  @override
  void initState() {
    super.initState();
    toDate = DateTime.now();
    fromDate = DateTime.now().subtract(const Duration(days: 7));
    
    // Initialize mock data
    allEntries = [
      HeartRateEntry(bpm: 78, timestamp: DateTime.now().subtract(const Duration(hours: 1))),
      HeartRateEntry(bpm: 95, timestamp: DateTime.now().subtract(const Duration(hours: 4))),
      HeartRateEntry(bpm: 72, timestamp: DateTime.now().subtract(const Duration(hours: 10))),
      HeartRateEntry(bpm: 105, timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2))),
      HeartRateEntry(bpm: 82, timestamp: DateTime.now().subtract(const Duration(days: 2))),
      HeartRateEntry(bpm: 88, timestamp: DateTime.now().subtract(const Duration(days: 3))),
      HeartRateEntry(bpm: 92, timestamp: DateTime.now().subtract(const Duration(days: 4))),
      HeartRateEntry(bpm: 75, timestamp: DateTime.now().subtract(const Duration(days: 8))), // Outside default range
    ];
    
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      filteredEntries = allEntries.where((entry) {
        final date = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
        final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
        final end = DateTime(toDate.year, toDate.month, toDate.day);
        
        return date.isAtSameMomentAs(start) || 
               date.isAtSameMomentAs(end) || 
               (date.isAfter(start) && date.isBefore(end));
      }).toList();
      
      // Sort by latest first
      filteredEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
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
      _applyFilter();
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
      _applyFilter();
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
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Heart Rate Log', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildRangeSelector(),
          Expanded(
            child: filteredEntries.isEmpty 
              ? _buildEmptyState()
              : _buildLogList(),
          ),
          _buildExportButton(),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildDateTile("FROM", fromDate, () => _selectFromDate(context)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDateTile("TO", toDate, () => _selectToDate(context)),
          ),
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
          Icon(Icons.favorite_border, size: 64, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No data for this range',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: filteredEntries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildLogCard(filteredEntries[index]);
      },
    );
  }

  Widget _buildLogCard(HeartRateEntry entry) {
    final bool isElevated = entry.bpm > 90;
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
            child: Icon(
              Icons.favorite_rounded, 
              color: isElevated ? coral : AppColors.primary, 
              size: 20
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.bpm} BPM',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C1C1E),
                  ),
                ),
                Text(
                  DateFormat('MMMM dd, hh:mm AA').format(entry.timestamp),
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

  Widget _buildExportButton() {
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
              // Functional placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting logs...')),
              );
            },
            child: Center(
              child: Text(
                "EXPORT LOGS",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
