import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/appointment_model.dart';
import '../../providers/providers.dart';
import '../profile_screen.dart';

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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFFC09D),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF181818),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (newDate != null && mounted) {
      final newTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(appt.date),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFFFC09D),
                secondary: Color(0xFFFFCACB),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Color(0xFF181818),
              ),
            ),
            child: child!,
          );
        },
      );
      if (newTime != null) {
        final finalDateTime = DateTime(newDate.year, newDate.month, newDate.day, newTime.hour, newTime.minute);
        ref.read(appointmentProvider.notifier).rescheduleAppointment(appt.id, finalDateTime);
      }
    }
  }

  Future<void> _editDoctorInfo(AppointmentModel appt) async {
    final nameCtrl = TextEditingController(text: appt.doctorName);
    final roleCtrl = TextEditingController(text: appt.location);
    // Use a local phone field — stored in location field as 'role | phone' if phone present
    final parts = appt.location.split(' | ');
    if (parts.length == 2) {
      roleCtrl.text = parts[0];
    }
    final phoneCtrl = TextEditingController(text: parts.length == 2 ? parts[1] : '');

    InputDecoration _blushDecoration(String hint, {Widget? prefix}) {
      return InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: const Color(0xFF181818).withOpacity(0.3), fontSize: 14),
        prefixIcon: prefix,
        filled: true,
        fillColor: const Color(0xFFFFFAF8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: const Color(0xFFFFC09D).withOpacity(0.35), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFC09D), width: 2),
        ),
      );
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24, right: 24, top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC09D).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.edit, color: Color(0xFFFFC09D), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Edit Doctor Info',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF181818)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('DOCTOR NAME', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFF181818).withOpacity(0.35))),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF181818)),
              decoration: _blushDecoration('e.g. Dr. Helena Smith',
                prefix: const Icon(Icons.person_outline, color: Color(0xFFFFC09D), size: 20)),
            ),
            const SizedBox(height: 16),
            Text('SPECIALIZATION / ROLE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFF181818).withOpacity(0.35))),
            const SizedBox(height: 8),
            TextField(
              controller: roleCtrl,
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF181818)),
              decoration: _blushDecoration('e.g. General Practitioner',
                prefix: const Icon(Icons.medical_services_outlined, color: Color(0xFFFFC09D), size: 20)),
            ),
            const SizedBox(height: 16),
            Text('CONTACT NUMBER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFF181818).withOpacity(0.35))),
            const SizedBox(height: 8),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF181818)),
              decoration: _blushDecoration('+1 (555) 000-0000',
                prefix: const Icon(Icons.call_outlined, color: Color(0xFFFFC09D), size: 20)),
            ),
            const SizedBox(height: 24),
            // Save button
            GestureDetector(
              onTap: () {
                final role = roleCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final locationValue = phone.isNotEmpty ? '$role | $phone' : role;
                ref.read(appointmentProvider.notifier).updateAppointment(
                  appt.copyWith(doctorName: nameCtrl.text.trim(), location: locationValue),
                );
                Navigator.pop(ctx);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFFFFC09D).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Text('Cancel', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF181818).withOpacity(0.4), fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(appointmentProvider);
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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Basic Background Gradient (Peach to Blush horizontal linear, same as HTML gradient)
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
          
          // Gloss/Frost overlay from HTML bg::before
          Positioned.fill(
            child: Container(
              color: const Color(0xFFFFFDFB).withOpacity(0.4),
            ),
          ),

          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                children: [
                   // TOP HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeaderButton(Icons.arrow_back, () => Navigator.pop(context)),
                        Text(
                          'Appointment',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF181818),
                          ),
                        ),
                        _buildHeaderButton(Icons.more_vert, () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        )),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // DATE SUMMARY ROW
                        GestureDetector(
                          onTap: () => _reschedule(targetAppt),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2DDD7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.calendar_today, color: Color(0xFFE9A48E), size: 24),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      targetAppt.date.difference(DateTime.now()).inDays == 0 ? 'Today' : DateFormat('EEEE').format(targetAppt.date),
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.6)),
                                    ),
                                    Text(
                                      DateFormat('MMMM d, yyyy').format(targetAppt.date),
                                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF181818)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // DOCTOR CARD (card-cream)
                        GestureDetector(
                          onTap: () => _editDoctorInfo(targetAppt),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8EEE9),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 24, offset: Offset(0, 8))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2DDD7),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
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
                                      Text(
                                        targetAppt.doctorName.isNotEmpty ? targetAppt.doctorName : 'Add Doctor Name',
                                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF181818), height: 1.1),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        targetAppt.location.isNotEmpty ? targetAppt.location : 'Add Department/Role',
                                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF181818).withOpacity(0.5)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // COUNTDOWN HIGHLIGHT
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF7D8CF), Color(0xFFF5D2C7)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 24, offset: Offset(0, 8))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${targetAppt.date.difference(DateTime.now()).inDays >= 0 ? targetAppt.date.difference(DateTime.now()).inDays : 0} Days Remaining',
                                style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: const Color(0xFF181818)),
                              ),
                              const SizedBox(height: 4),
                              Text('Until your appointment', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF181818).withOpacity(0.6))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // CALENDAR BUTTON
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Added ${targetAppt.title} to Device Calendar'),
                                  backgroundColor: const Color(0xFF40916C),
                                ));
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.event_note, color: Color(0xFF181818)),
                                    const SizedBox(width: 8),
                                    Text('Add to Calendar', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF181818))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // PREPARATION CHECKLIST
                        Text('Preparation Checklist', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF181818).withOpacity(0.6))),
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
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                                  boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1))],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item['title'], style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF181818))),
                                    Container(
                                      width: 24, height: 24,
                                      decoration: BoxDecoration(
                                        color: item['checked'] ? const Color(0xFFF2C6B8).withOpacity(0.2) : Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: item['checked'] ? Colors.transparent : const Color(0xFFF2C6B8).withOpacity(0.4)),
                                      ),
                                      child: item['checked'] ? const Icon(Icons.check, size: 18, color: Color(0xFFF2C6B8)) : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton.icon(
                            onPressed: () async {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                                dialogTitle: 'Select Medical Report',
                              );
                              if (result != null && result.files.isNotEmpty && mounted) {
                                final file = result.files.first;
                                final fileName = file.name;
                                final filePath = file.path ?? '';
                                ref.read(appointmentProvider.notifier).attachReport(targetAppt.id, filePath, fileName);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Report "$fileName" attached.'),
                                    backgroundColor: const Color(0xFF40916C),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.attach_file, color: Color(0xCC181818), size: 16),
                            label: Text('Attach Report', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xCC181818))),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFF4E4DE),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                          ),
                        ),
                        if (targetAppt.reportFileName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Center(child: Text('Attached: ${targetAppt.reportFileName}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF181818).withOpacity(0.5)))),
                          ),
                        const SizedBox(height: 32),

                        // PREVIOUS HISTORY
                        Text('Previous History', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF181818).withOpacity(0.6))),
                        const SizedBox(height: 16),
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Icon(icon, color: const Color(0xFF181818), size: 24),
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
          color: Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 24, offset: Offset(0, 8))],
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9A48E).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('COMPLETED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFE9A48E), letterSpacing: -0.5)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(appt.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF181818))),
            const SizedBox(height: 4),
            Text('Doctor: ${appt.doctorName}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF181818).withOpacity(0.5), height: 1.5)),
          ],
        ),
      ),
    );
  }
}