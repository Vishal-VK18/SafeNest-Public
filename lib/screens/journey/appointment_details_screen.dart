// lib/screens/journey/appointment_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../providers/providers.dart';
import '../../../models/appointment_model.dart';
import '../caregiver_management_screen.dart';

// ─── Helper Colors ────────────────────────────────────────────────────────────
const _lilacDark = Color(0xFF8E7DA0);
const _lilacMid = Color(0xFFD8B4FE);
const _lilacLight = Color(0xFFF3E8FF);
const _lilacBg = Color(0xFFF8F4FF);

class AppointmentDetailsScreen extends ConsumerStatefulWidget {
  const AppointmentDetailsScreen({super.key});

  @override
  ConsumerState<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState
    extends ConsumerState<AppointmentDetailsScreen> {
  // ─── Local checklist state ─────────────────────────────────────────────────
  final List<Map<String, dynamic>> _tasks = [
    {'title': 'Blood Test', 'subtitle': 'Fast for 8 hours prior', 'checked': true},
    {'title': 'Ultrasound', 'subtitle': 'Standard checkup', 'checked': false},
    {'title': 'Vaccine Reminder', 'subtitle': 'Flu shot update', 'checked': false},
  ];

  // ─── Past visits (static seeds, completed appts injected below) ──────────
  final List<Map<String, String>> _pastVisits = [
    {'title': 'Initial Consultation', 'subtitle': 'Sept 10, 2024 • Normal', 'icon': 'history'},
    {'title': 'First Ultrasound', 'subtitle': 'Aug 15, 2024 • Healthy', 'icon': 'medical'},
  ];

  // ─── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(appointmentProvider.notifier);
      if (ref.read(appointmentProvider).isEmpty) {
        notifier.addAppointment(AppointmentModel(
          id: '1',
          title: 'Ultrasound Checkup',
          doctorName: 'Dr. Helena Smith',
          location: 'City Women\'s Hospital',
          department: 'Obstetrics & Gynaecology',
          contactNumber: '+94 11 234 5678',
          date: DateTime.now().add(const Duration(days: 3)),
        ));
      }
      notifier.checkReminders();
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(appointmentProvider);
    final riskScore = ref.watch(riskScoreProvider);
    final preg = ref.watch(pregnancyProvider);
    final hyd = ref.watch(hydrationProvider);

    // Upcoming appointment (first non-completed, non-missed)
    final upcomingAppt = appointments.firstWhere(
      (a) => !a.isCompleted && !a.isMissed,
      orElse: () => AppointmentModel(
        id: '',
        title: '',
        doctorName: 'Dr. Helena Smith',
        location: 'City Women\'s Hospital',
        date: DateTime.now().add(const Duration(days: 3)),
      ),
    );

    final missedAppt = appointments.firstWhere(
      (a) => a.isMissed,
      orElse: () => AppointmentModel(
          id: '', title: '', doctorName: '', location: '', date: DateTime.now()),
    );

    final hasMissed = missedAppt.id.isNotEmpty;
    final daysRemaining =
        upcomingAppt.date.difference(DateTime.now()).inDays.clamp(0, 999);

    // Completed appointments merged into past visits list
    final completedAppts = appointments.where((a) => a.isCompleted).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_lilacLight, Colors.white],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _circleButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => Navigator.pop(context),
                      ),
                      Text(
                        'Appointment Details',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      // Three-dot menu
                      _circleButton(
                        icon: Icons.more_horiz,
                        onTap: () => _showThreeDotsMenu(context, upcomingAppt),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Doctor card (tappable to edit)
                  GestureDetector(
                    onTap: () => _showEditDoctorSheet(context, upcomingAppt),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _lilacLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _lilacLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _lilacLight),
                            ),
                            child: const Icon(
                              Icons.local_hospital_outlined,
                              color: _lilacDark,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  upcomingAppt.doctorName.isEmpty
                                      ? 'Tap to add doctor'
                                      : upcomingAppt.doctorName,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  upcomingAppt.location,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (upcomingAppt.department.isNotEmpty)
                                  Text(
                                    upcomingAppt.department,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: _lilacDark,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month,
                                        color: _lilacMid, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${upcomingAppt.date.month}/${upcomingAppt.date.day}/${upcomingAppt.date.year}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.edit_outlined,
                                        size: 12, color: _lilacDark),
                                  ],
                                ),
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
          ),

          // ── Body ────────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── PART 1: Risk-Aware Health Banner ────────────────────────
                _buildRiskBanner(riskScore),
                const SizedBox(height: 16),

                // ── PART 5: Missed Appointment Banner ───────────────────────
                if (hasMissed) ...[
                  _buildMissedBanner(missedAppt),
                  const SizedBox(height: 16),
                ],

                // ── Countdown Card ─────────────────────────────────────────
                _buildCountdownCard(context, upcomingAppt, daysRemaining),
                const SizedBox(height: 24),

                // ── PART 2: Visit Preparation Tips ─────────────────────────
                _buildPreparationTips(preg.pregnancyWeek, hyd.intakeLiters),
                const SizedBox(height: 24),

                // ── Medical Checklist ──────────────────────────────────────
                _buildMedicalChecklist(),
                const SizedBox(height: 8),

                // ── PART 3: Attach Medical Report ──────────────────────────
                _buildReportSection(context, upcomingAppt),
                const SizedBox(height: 24),

                // ── PART 6: Previous History + View Trends ─────────────────
                _buildPreviousHistory(context, completedAppts),
                const SizedBox(height: 32),

                // ── Emergency Contact ──────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CaregiverManagementScreen()),
                  ),
                  icon: const Icon(Icons.emergency, color: _lilacDark),
                  label: Text(
                    'Emergency Contact',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: _lilacDark,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                    side: const BorderSide(color: _lilacDark, width: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PART 1 — Risk Banner
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildRiskBanner(int riskScore) {
    Color bg, borderColor, iconColor;
    IconData icon;
    String message;

    if (riskScore == 0) {
      bg = Colors.green.shade50;
      borderColor = Colors.green.shade200;
      iconColor = Colors.green.shade700;
      icon = Icons.check_circle_outline;
      message = 'Health Stable – On Track for Visit';
    } else if (riskScore <= 2) {
      bg = Colors.amber.shade50;
      borderColor = Colors.amber.shade200;
      iconColor = Colors.amber.shade800;
      icon = Icons.warning_amber_outlined;
      message = 'Mild Health Risk Detected – Monitor Closely';
    } else {
      bg = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      iconColor = Colors.red.shade700;
      icon = Icons.health_and_safety_outlined;
      message = 'High Risk Detected – Inform Doctor During Visit';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PART 5 — Missed Banner
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildMissedBanner(AppointmentModel missed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.event_busy_outlined, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointment Missed – Please Reschedule Immediately',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                Text(
                  '${missed.doctorName} • ${missed.date.month}/${missed.date.day}/${missed.date.year}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.red.shade500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showRescheduleDialog(context, missed),
            child: Text(
              'Reschedule',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Countdown Card
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildCountdownCard(
      BuildContext context, AppointmentModel appt, int daysRemaining) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _lilacBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lilacLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COUNTDOWN',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appt.isMissed
                        ? 'Missed'
                        : '$daysRemaining Days Remaining',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: appt.isMissed
                          ? Colors.red.shade700
                          : _lilacDark,
                    ),
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  appt.isMissed ? Icons.error_outline : Icons.alarm,
                  color: appt.isMissed ? Colors.red : _lilacMid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _addToCalendar(appt),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: _lilacDark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Add to Calendar',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PART 2 — Visit Preparation Tips
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPreparationTips(int pregnancyWeek, double hydrationLiters) {
    final int trimester = pregnancyWeek <= 13
        ? 1
        : (pregnancyWeek <= 26 ? 2 : 3);
    final tips = <Map<String, dynamic>>[
      {
        'icon': Icons.water_drop_outlined,
        'text': hydrationLiters < 1.5
            ? 'Drink at least 500ml of water before your visit'
            : 'Stay hydrated – you\'re on track with ${hydrationLiters.toStringAsFixed(1)}L today',
      },
      {
        'icon': Icons.folder_copy_outlined,
        'text': 'Carry all previous medical reports and prescriptions',
      },
      {
        'icon': Icons.notes_outlined,
        'text': 'Note any unusual symptoms to discuss with your doctor',
      },
      if (trimester == 3)
        {
          'icon': Icons.favorite_border,
          'text': 'Track baby movements – report if < 10 kicks in 2 hours',
        },
      if (trimester == 1)
        {
          'icon': Icons.no_food_outlined,
          'text': 'Fast for 8 hours if blood work has been requested',
        },
      if (trimester == 2)
        {
          'icon': Icons.monitor_heart_outlined,
          'text': 'Glucose screening may be required at this stage',
        },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Before This Visit',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _lilacLight),
          ),
          child: Column(
            children: tips.asMap().entries.map((e) {
              final isLast = e.key == tips.length - 1;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: _lilacLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        e.value['icon'] as IconData,
                        color: _lilacDark,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      e.value['text'] as String,
                      style: GoogleFonts.inter(fontSize: 13, height: 1.4),
                    ),
                    dense: true,
                  ),
                  if (!isLast)
                    const Divider(color: _lilacLight, height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Medical Checklist
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildMedicalChecklist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Medical Checklist',
              style:
                  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _lilacLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_tasks.length} TASKS',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _lilacMid,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._tasks.asMap().entries.map((entry) {
          final idx = entry.key;
          final task = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _lilacLight),
            ),
            child: CheckboxListTile(
              value: task['checked'] as bool,
              onChanged: (val) => setState(() => _tasks[idx]['checked'] = val),
              activeColor: _lilacMid,
              checkColor: Colors.white,
              side: const BorderSide(color: _lilacLight, width: 2),
              title: Text(
                task['title'] as String,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                task['subtitle'] as String,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PART 3 — Medical Report Section
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildReportSection(BuildContext context, AppointmentModel appt) {
    final hasReport = appt.reportFilePath != null && appt.reportFilePath!.isNotEmpty;

    if (hasReport) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _lilacBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _lilacLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attached Medical Report',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _lilacLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.description_outlined, color: _lilacDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt.reportFileName ?? 'report',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (appt.reportUploadDate != null)
                        Text(
                          'Uploaded ${appt.reportUploadDate!.month}/${appt.reportUploadDate!.day}/${appt.reportUploadDate!.year}',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickReport(appt),
                    icon: const Icon(Icons.upload_file, size: 16, color: _lilacDark),
                    label: Text('Replace',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _lilacDark)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _lilacMid),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (appt.id.isNotEmpty) {
                        ref
                            .read(appointmentProvider.notifier)
                            .removeReport(appt.id);
                      }
                    },
                    icon: Icon(Icons.delete_outline,
                        size: 16, color: Colors.red.shade600),
                    label: Text('Delete',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade600)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade200),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => _pickReport(appt),
      icon: const Icon(Icons.attach_file, color: _lilacMid),
      label: Text(
        'Attach Medical Report',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: _lilacMid,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        side: const BorderSide(color: _lilacMid, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PART 6 — Previous History + View Trends Button
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPreviousHistory(
      BuildContext context, List<AppointmentModel> completedAppts) {
    final allPast = [
      ..._pastVisits.map((v) => _buildHistoryTile(
            icon: v['icon'] == 'history'
                ? Icons.history
                : Icons.medical_services,
            title: v['title']!,
            subtitle: v['subtitle']!,
          )),
      ...completedAppts.map((a) => _buildHistoryTile(
            icon: Icons.check_circle_outline,
            title: a.title.isNotEmpty ? a.title : a.doctorName,
            subtitle:
                '${a.date.month}/${a.date.day}/${a.date.year} • Completed',
          )),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Previous History',
              style:
                  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => _showTrendsModal(context, completedAppts),
              icon: const Icon(Icons.bar_chart, size: 16, color: _lilacDark),
              label: Text(
                'View Trends',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _lilacDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _lilacLight),
          ),
          child: Column(
            children: allPast.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No history yet.',
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    )
                  ]
                : allPast
                    .expand((w) => [
                          w,
                          const Divider(color: _lilacLight, height: 1),
                        ])
                    .toList()
                  ..removeLast(),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Shared Widgets
  // ──────────────────────────────────────────────────────────────────────────
  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
      child: IconButton(icon: Icon(icon, size: 20), onPressed: onTap),
    );
  }

  Widget _buildHistoryTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: _lilacLight, shape: BoxShape.circle),
        child: Icon(icon, color: _lilacMid, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[300]),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PART 4 — Three Dot Menu
  // ──────────────────────────────────────────────────────────────────────────
  void _showThreeDotsMenu(BuildContext context, AppointmentModel appt) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _menuTile(
                  context,
                  icon: Icons.edit_outlined,
                  label: 'Edit Appointment',
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDoctorSheet(context, appt);
                  },
                ),
                _menuTile(
                  context,
                  icon: Icons.event_repeat,
                  label: 'Reschedule',
                  onTap: () {
                    Navigator.pop(context);
                    _showRescheduleDialog(context, appt);
                  },
                ),
                _menuTile(
                  context,
                  icon: Icons.check_circle_outline,
                  label: 'Mark as Completed',
                  onTap: () {
                    Navigator.pop(context);
                    if (appt.id.isNotEmpty) {
                      ref
                          .read(appointmentProvider.notifier)
                          .markCompleted(appt.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Appointment marked as completed.')),
                      );
                    }
                  },
                ),
                _menuTile(
                  context,
                  icon: Icons.cancel_outlined,
                  label: 'Cancel Appointment',
                  color: Colors.red.shade700,
                  onTap: () {
                    Navigator.pop(context);
                    if (appt.id.isNotEmpty) {
                      ref
                          .read(appointmentProvider.notifier)
                          .deleteAppointment(appt.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Appointment has been cancelled.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuTile(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      Color color = _lilacDark}) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, color: color)),
      onTap: onTap,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PART 7 — Edit Doctor Details Bottom Sheet
  // ──────────────────────────────────────────────────────────────────────────
  void _showEditDoctorSheet(BuildContext context, AppointmentModel appt) {
    final docCtrl = TextEditingController(text: appt.doctorName);
    final hospCtrl = TextEditingController(text: appt.location);
    final deptCtrl = TextEditingController(text: appt.department);
    final phoneCtrl = TextEditingController(text: appt.contactNumber);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Edit Doctor Details',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildFormField('Doctor Name', docCtrl,
                    icon: Icons.person_outline),
                const SizedBox(height: 12),
                _buildFormField('Hospital Name', hospCtrl,
                    icon: Icons.local_hospital_outlined),
                const SizedBox(height: 12),
                _buildFormField('Department', deptCtrl,
                    icon: Icons.category_outlined, required: false),
                const SizedBox(height: 12),
                _buildFormField('Contact Number', phoneCtrl,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    required: false),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final updated = appt.copyWith(
                        doctorName: docCtrl.text.trim(),
                        location: hospCtrl.text.trim(),
                        department: deptCtrl.text.trim(),
                        contactNumber: phoneCtrl.text.trim(),
                      );
                      ref
                          .read(appointmentProvider.notifier)
                          .updateAppointment(updated);
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: _lilacDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController ctrl, {
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: _lilacDark) : null,
        labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lilacLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lilacDark, width: 2),
        ),
        filled: true,
        fillColor: _lilacBg,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Reschedule Dialog
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _showRescheduleDialog(
      BuildContext context, AppointmentModel appt) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _lilacDark),
        ),
        child: child!,
      ),
    );
    if (picked != null && appt.id.isNotEmpty) {
      ref
          .read(appointmentProvider.notifier)
          .rescheduleAppointment(appt.id, picked);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Rescheduled to ${picked.month}/${picked.day}/${picked.year}'),
          ),
        );
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PART 6 — Past Visit Analytics Modal
  // ──────────────────────────────────────────────────────────────────────────
  void _showTrendsModal(
      BuildContext context, List<AppointmentModel> completed) {
    final allVisits = _pastVisits.length + completed.length;
    final completedCount = _pastVisits.length + completed.length;
    final missedCount = ref
        .read(appointmentProvider)
        .where((a) => a.isMissed)
        .length;
    final completionRate = allVisits == 0
        ? 100
        : ((completedCount / (completedCount + missedCount)) * 100).round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Appointment Trends',
                    style: GoogleFonts.inter(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _trendCard(
                          '$completionRate%',
                          'Completion Rate',
                          Colors.green.shade50,
                          Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _trendCard(
                          '$missedCount',
                          'Missed Visits',
                          Colors.red.shade50,
                          Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _trendCard(
                          '$allVisits',
                          'Total Visits',
                          _lilacLight,
                          _lilacDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Visit Timeline',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: [
                        ..._pastVisits.map(
                          (v) => _timelineTile(
                            title: v['title']!,
                            subtitle: v['subtitle']!,
                            color: Colors.green.shade400,
                          ),
                        ),
                        ...completed.map(
                          (a) => _timelineTile(
                            title: a.title.isNotEmpty ? a.title : a.doctorName,
                            subtitle:
                                '${a.date.month}/${a.date.day}/${a.date.year} • Completed',
                            color: Colors.green.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _trendCard(
      String value, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.inter(fontSize: 10, color: textColor),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _timelineTile(
      {required String title,
      required String subtitle,
      required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Container(
                  width: 2,
                  height: 30,
                  color: Colors.grey[200]),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // File Picker & Calendar Actions
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _pickReport(AppointmentModel appt) async {
    if (appt.id.isEmpty) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        ref.read(appointmentProvider.notifier).attachReport(
              appt.id,
              file.path ?? '',
              file.name,
            );
      }
    } catch (_) {
      // File picker cancelled or permission denied – do nothing
    }
  }

  void _addToCalendar(AppointmentModel appt) {
    // Show a snackbar — full calendar integration would require device-specific plugins
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Appointment saved: ${appt.doctorName} on ${appt.date.month}/${appt.date.day}/${appt.date.year}',
        ),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }
}
