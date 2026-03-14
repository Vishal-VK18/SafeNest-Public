import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart';
import '../../models/appointment_model.dart';

class CalendarService {

  /// Add appointment to device native calendar
  static Future<bool> addAppointmentToCalendar(
      AppointmentModel appointment) async {
    try {
      final Event event = Event(
        title: 'SafeNest: ${appointment.type} — '
               'Dr. ${appointment.doctorName}',
        description: _buildDescription(appointment),
        location: appointment.location,
        startDate: appointment.date,
        endDate: appointment.date.add(const Duration(hours: 1)),
        allDay: false,
        iosParams: IOSParams(
          reminder: const Duration(hours: 24),
          // 24 hour reminder before appointment
        ),
        androidParams: const AndroidParams(
          emailInvites: [],
        ),
      );

      Add2Calendar.addEvent2Cal(event);

      debugPrint('[SafeNest Calendar] ✅ Event added to calendar: '
                 '${appointment.type}');
      return true;

    } catch (e) {
      debugPrint('[SafeNest Calendar] ❌ Add to calendar error: $e');
      return false;
    }
  }

  static String _buildDescription(AppointmentModel appointment) {
    final buffer = StringBuffer();
    buffer.writeln('SafeNest Appointment');
    buffer.writeln('Doctor: Dr. ${appointment.doctorName}');
    if (appointment.doctorSpecialty != null) {
      buffer.writeln('Specialty: ${appointment.doctorSpecialty}');
    }
    buffer.writeln('Type: ${appointment.type}');
    if (appointment.location.isNotEmpty) {
      buffer.writeln('Location: ${appointment.location}');
    }
    if (appointment.notes != null && appointment.notes!.isNotEmpty) {
      buffer.writeln('Notes: ${appointment.notes}');
    }
    if (appointment.preparationChecklist != null &&
        appointment.preparationChecklist!.isNotEmpty) {
      buffer.writeln('\nPreparation Checklist:');
      for (final item in appointment.preparationChecklist!) {
        buffer.writeln('• $item');
      }
    }
    return buffer.toString();
  }
}
