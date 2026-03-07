// lib/screens/safety_event_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/safety_event_model.dart';
import '../providers/providers.dart';
import '../utils/app_theme.dart';

class SafetyEventHistoryScreen extends ConsumerStatefulWidget {
  const SafetyEventHistoryScreen({super.key});

  @override
  ConsumerState<SafetyEventHistoryScreen> createState() => _SafetyEventHistoryScreenState();
}

class _SafetyEventHistoryScreenState extends ConsumerState<SafetyEventHistoryScreen> {
  String _activeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(safetyHistoryProvider);
    
    final filteredHistory = history.where((event) {
      if (_activeFilter == 'All') return true;
      if (_activeFilter == 'Alerts') return event.type == SafetyEventType.fall || event.type == SafetyEventType.sos;
      if (_activeFilter == 'System') return event.type == SafetyEventType.system;
      if (_activeFilter == 'Vitals') return event.type == SafetyEventType.vitals;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildFilterChips(),
            Expanded(
              child: filteredHistory.isEmpty 
                ? _buildEmptyState()
                : _buildTimeline(filteredHistory),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              shape: const CircleBorder(),
            ),
          ),
          Text(
            'Event History',
            style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.bold,
              color: const Color(0xFF1C1C1E),
            ),
          ),
          IconButton(
            onPressed: () {}, // Filter logic
            icon: const Icon(Icons.tune, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Alerts', 'System', 'Vitals'];
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = _activeFilter == filters[i];
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = filters[i]),
            child: Chip(
              label: Text(filters[i]),
              labelStyle: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.primary,
              ),
              backgroundColor: selected ? AppColors.primary : AppColors.primary.withOpacity(0.1),
              shape: const StadiumBorder(),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No safety events recorded.',
            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<SafetyEventModel> events) {
    // Group by day for Today/Yesterday headers
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      itemCount: events.length,
      itemBuilder: (context, i) {
        final event = events[i];
        bool showHeader = false;
        String headerText = '';
        
        DateTime eventDay = DateTime(event.timestamp.year, event.timestamp.month, event.timestamp.day);
        
        if (i == 0 || DateTime(events[i-1].timestamp.year, events[i-1].timestamp.month, events[i-1].timestamp.day) != eventDay) {
          showHeader = true;
          if (eventDay == today) headerText = 'TODAY';
          else if (eventDay == yesterday) headerText = 'YESTERDAY';
          else headerText = DateFormat('MMMM d').format(eventDay).toUpperCase();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    headerText,
                    style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.bold,
                      color: Colors.grey[400], letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
            ],
            _buildTimelineItem(event, isLast: i == events.length - 1),
          ],
        );
      },
    );
  }

  Widget _buildTimelineItem(SafetyEventModel event, {required bool isLast}) {
    IconData icon;
    Color iconColor;
    Color bgIconColor;

    switch (event.type) {
      case SafetyEventType.fall:
      case SafetyEventType.sos:
        icon = Icons.emergency;
        iconColor = const Color(0xFFF2A0A0);
        bgIconColor = iconColor.withOpacity(0.2);
        break;
      case SafetyEventType.system:
        icon = Icons.portable_wifi_off;
        iconColor = AppColors.primary;
        bgIconColor = iconColor.withOpacity(0.2);
        break;
      case SafetyEventType.vitals:
        icon = Icons.monitor_heart;
        iconColor = const Color(0xFFF4C291);
        bgIconColor = iconColor.withOpacity(0.2);
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: bgIconColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getEventTitle(event),
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('hh:mm a').format(event.timestamp),
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600], height: 1.4),
                  ),
                  if (event.status == SafetyEventStatus.resolved) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(
                            'RESOLVED',
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEventTitle(SafetyEventModel event) {
    switch (event.type) {
      case SafetyEventType.fall: return 'Fall Detected';
      case SafetyEventType.sos:  return 'Manual SOS Alert';
      case SafetyEventType.system: return 'System Alert';
      case SafetyEventType.vitals: return 'Vitals Alert';
    }
  }
}
