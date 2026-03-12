import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/safety_event_model.dart';
import '../../providers/providers.dart';

class EventHistoryScreen extends ConsumerStatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  ConsumerState<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends ConsumerState<EventHistoryScreen> {
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
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFC09D),
              Color(0xFFFFCACB),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildFilterChips(),
              Expanded(
                child: filteredHistory.isEmpty 
                  ? _buildEmptyState()
                  : _buildTimeline(filteredHistory),
              ),
              _buildMonitoringActiveBanner(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(Icons.chevron_left, () => Navigator.pop(context)),
          Text(
            'Event History',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF181818),
              letterSpacing: -0.5,
            ),
          ),
          _buildCircleButton(Icons.tune, () {}),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF181818), size: 24),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Alerts', 'System', 'Vitals'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final selected = _activeFilter == filters[i];
            return GestureDetector(
              onTap: () => setState(() => _activeFilter = filters[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFFC09D) : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  filters[i],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected ? Colors.white : const Color(0xFF181818),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 56, color: const Color(0xFF6F6F6F).withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No events recorded',
            style: GoogleFonts.inter(color: const Color(0xFF6F6F6F), fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'All clear! The wearable is monitoring.',
            style: GoogleFonts.inter(color: const Color(0xFF6F6F6F), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<SafetyEventModel> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
          children: [
            if (showHeader) ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  Text(
                    headerText,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9A9A9A),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Divider(color: Color(0xFFF4D2C8), thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),
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

    switch (event.type) {
      case SafetyEventType.fall:
      case SafetyEventType.sos:
        icon = Icons.emergency;
        iconColor = const Color(0xFFFF9E9E);
        break;
      case SafetyEventType.system:
        icon = Icons.portable_wifi_off;
        iconColor = const Color(0xFFC9C9E0);
        break;
      case SafetyEventType.vitals:
        icon = Icons.monitor_heart;
        iconColor = const Color(0xFFFFC09D);
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              if (!isLast)
                Positioned(
                  top: 40,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: const Color(0xFFF4D2C8),
                  ),
                ),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE5DA),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 32),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
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
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF181818),
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy • HH:mm').format(event.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6F6F6F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6F6F6F),
                      height: 1.5,
                    ),
                  ),
                  if (event.status == SafetyEventStatus.resolved) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7EE),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E7D5B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'RESOLVED',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E7D5B),
                              letterSpacing: 0.5,
                            ),
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
      case SafetyEventType.sos:  return 'SOS Triggered';
      case SafetyEventType.system: return 'System Alert';
      case SafetyEventType.vitals: return 'Heart Rate Alert';
    }
  }

  Widget _buildMonitoringActiveBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFC09D).withOpacity(0.2), width: 2),
                image: const DecorationImage(
                  image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCA5goerGPltcfI5R0W3SJrj9HhBPI2loAT_utskaOrbmBEl8VDUmQeEqyY5xugVXDsPB5I6S7WCVouzEHlZZjTjtD3BBiu4E9lydpjouOISGGWTsktcjhmXXaWo29M2fGp3ICAx6TI-E6tPBU7HHXgg0u_Q6I2Jz718F1KlyIBdQqXP54Hb5XslnJBslIa6TrZbyZRf6lOg610uLbsTwtVRqeclBBfShQtzg8ois_bXTm3I4AM4Df7vDMKtiiVaCT5MPmP9ph6_r-V'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MONITORING ACTIVE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFC09D),
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    'Sarah Henderson',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF181818),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.favorite, color: Color(0xFF4CAF7A), size: 16),
                const SizedBox(width: 4),
                Text(
                  'Normal',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4CAF7A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
