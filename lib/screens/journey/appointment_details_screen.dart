import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../providers/providers.dart';

class AppointmentDetailsScreen extends ConsumerStatefulWidget {
  const AppointmentDetailsScreen({super.key});

  @override
  ConsumerState<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}
class _AppointmentDetailsScreenState extends ConsumerState<AppointmentDetailsScreen> {
  final List<Map<String, dynamic>> _checklist = [
    {'title': 'Blood Test', 'checked': true},
    {'title': 'Ultrasound', 'checked': false},
    {'title': 'Vaccine', 'checked': false},
  ];

  Future<void> _reschedule(AppointmentModel appt) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: appt.date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (newDate != null && mounted) {
      final newTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(appt.date),
      );
      if (newTime != null) {
        final finalDateTime = DateTime(newDate.year, newDate.month, newDate.day, newTime.hour, newTime.minute);
        ref.read(appointmentProvider.notifier).rescheduleAppointment(appt.id, finalDateTime);
      }
    }
  }

  Future<void> _editDoctorInfo(AppointmentModel appt) async {
    final nameCtrl = TextEditingController(text: appt.doctorName);
    final locCtrl = TextEditingController(text: appt.location);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Doctor Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Doctor Name')),
            TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Department / Role')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(appointmentProvider.notifier).updateAppointment(
                appt.copyWith(doctorName: nameCtrl.text, location: locCtrl.text)
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(appointmentProvider);
    // Use the first active appointment, or fallback to a default mock model aligning with UI text.
    final targetAppt = appointments.firstWhere(
      (a) => !a.isCompleted, 
      orElse: () => AppointmentModel(
        id: 'mock_1',
        title: 'Checkup',
        doctorName: 'Sandra Perry',
        location: 'General Practitioner',
        date: DateTime.now().add(const Duration(days: 2)),
      )
    );

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (Peach to Blush horizontal)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)], // Peach to Blush
                ),
              ),
            ),
          ),
          // Foggy Cream Overlay (Cream overlay to whiteish bottom)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFFDFB).withOpacity(0.85),
                    const Color(0xFFFFFDFB).withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),
          
          // Diffusion Orbs
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFCACB).withOpacity(0.3),
                    const Color(0xFFFFC09D).withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 200,
            left: -160,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFCACB).withOpacity(0.3),
                    const Color(0xFFFFC09D).withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Header (Back Button, Title, More Info)
                Padding(
                  padding: const EdgeInsets.only(left: 28, right: 28, top: 24, bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withOpacity(0.4)),
                          ),
                          child: const Icon(Icons.arrow_back, color: Color(0xFF181818), size: 24),
                        ),
                      ),
                      Text(
                        'Appointment',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181818),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.more_vert, color: Color(0xFF181818), size: 24),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
                    children: [
                      // Date Selector
                      GestureDetector(
                        onTap: () => _reschedule(targetAppt),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.5)),
                              ),
                              child: Icon(Icons.calendar_today, color: const Color(0xFF181818).withOpacity(0.7), size: 22),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(targetAppt.date.difference(DateTime.now()).inDays == 0 ? 'Today' : DateFormat('EEEE').format(targetAppt.date), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.5))),
                                const SizedBox(height: 2),
                                Text(DateFormat('MMMM d, yyyy - h:mm a').format(targetAppt.date), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF181818))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Doctor Info Tag
                      GestureDetector(
                        onTap: () => _editDoctorInfo(targetAppt),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.5)),
                            boxShadow: const [BoxShadow(color: Color(0x1AFFC09D), blurRadius: 20, offset: Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                                  image: const DecorationImage(
                                    image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDxUahFZlLNPAFNq6UMAo6AhmVyEcbrAw9JrWGNMU0Zj1QWPwC_-dtX6XKTzfePUG6v4ut9P4ww6C2pkRR-tK0ACDfpzRaP-yTdCPqbJzJ7OR0_yGJaISJWceJKVcEGPVnFG-vt3aQRzsBvHEL-P43TS2N5veQ4V_l3XJlhtbiTSvqYfdm6t5x0-vFhMOFzkl-UoxPaj3vOQmA0R4vP3LEk2SeK4HIeGKNzVy3dofWxTJI199OsVZbH3aFtAdZYCYyQqVGrcq0JPiIP'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(targetAppt.doctorName.isNotEmpty ? targetAppt.doctorName : 'Add Doctor Name', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF181818)), overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(targetAppt.location.isNotEmpty ? targetAppt.location : 'Add Department/Role', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF181818).withOpacity(0.5)), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Days Remaining Countdown Melting Tag
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0x99FFC09D), Color(0x66FFCACB)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${targetAppt.date.difference(DateTime.now()).inDays >= 0 ? targetAppt.date.difference(DateTime.now()).inDays : 0} Days Remaining', style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.bold, height: 1.1, letterSpacing: -0.5, color: const Color(0xFF181818))),
                            const SizedBox(height: 4),
                            Text('Until your appointment', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.6))),
                            const SizedBox(height: 32),
                            // Button PEACH TO BLUSH
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [BoxShadow(color: Color(0x4DFFC09D), blurRadius: 15, offset: Offset(0, 4))],
                              ),
                              child: TextButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Added ${targetAppt.title} to Device Calendar'),
                                    backgroundColor: const Color(0xFF40916C),
                                  ));
                                },
                                icon: const Icon(Icons.event_available, color: Color(0xFF181818)),
                                label: Text(
                                  'Add to Calendar',
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF181818)),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Preparation Checklist
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text('Preparation Checklist', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF181818).withOpacity(0.6))),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: _checklist.map((item) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                item['checked'] = !item['checked'];
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item['title'], style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.8))),
                                  Container(
                                    width: 20, height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF181818).withOpacity(0.1), width: 1.5),
                                    ),
                                    child: item['checked'] ? const Icon(Icons.check, size: 14, color: Color(0xFFFFC09D)) : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Report attached successfully.'),
                              backgroundColor: Color(0xFF40916C),
                            ));
                            ref.read(appointmentProvider.notifier).attachReport(targetAppt.id, '/dummy/path.pdf', 'blood_work.pdf');
                          },
                          icon: const Icon(Icons.attach_file, color: Color(0xCC181818), size: 16),
                          label: Text('Attach Report', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xCC181818))),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                              side: BorderSide(color: Colors.white.withOpacity(0.6)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          ),
                        ),
                      ),
                      if (targetAppt.reportFileName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Center(child: Text('Attached: ${targetAppt.reportFileName}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF181818).withOpacity(0.5)))),
                        ),
                      const SizedBox(height: 24),

                      // Previous History
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text('Previous History', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF181818).withOpacity(0.6))),
                      ),
                      const SizedBox(height: 12),
                      
                      ...appointments.where((a) => a.isCompleted).map((appt) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildHistoryCard(appt),
                        );
                      }),
                      
                      if (appointments.where((a) => a.isCompleted).isEmpty)
                        Center(child: Text('No previous history recorded', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF181818).withOpacity(0.5)))),
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

  Widget _buildHistoryCard(AppointmentModel appt) {
    return GestureDetector(
      onTap: () => _editDoctorInfo(appt),
      onLongPress: () => _reschedule(appt),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.45),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          boxShadow: const [BoxShadow(color: Color(0x1AFFC09D), blurRadius: 20, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('MMM d, yyyy').format(appt.date).toUpperCase(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF181818).withOpacity(0.3), letterSpacing: 1.5)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('COMPLETED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade700, letterSpacing: -0.5)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(appt.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF181818))),
            const SizedBox(height: 4),
            Text('Doctor: ${appt.doctorName}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF181818).withOpacity(0.5), height: 1.5)),
          ],
        ),
      ),
    );
  }
}
