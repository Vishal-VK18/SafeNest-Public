// lib/screens/logs/fall_event_log_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class FallEventLogScreen extends StatelessWidget {
  const FallEventLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('Fall Event Log', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Fall Event History',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your fall event data will appear here.',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
