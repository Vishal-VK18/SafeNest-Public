// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancy = ref.watch(pregnancyProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      pregnancy.userName.isNotEmpty ? pregnancy.userName[0] : 'U',
                      style: GoogleFonts.inter(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoCard(
              context,
              label: 'User Name',
              value: pregnancy.userName,
              icon: Icons.person_outline,
              onTap: () => _editName(context, ref, pregnancy.userName),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              label: 'Pregnancy Week',
              value: pregnancy.pregnancyWeek > 0 ? 'Week ${pregnancy.pregnancyWeek}' : 'Not Set',
              icon: Icons.calendar_today_outlined,
              onTap: () => _editWeek(context, ref, pregnancy.pregnancyWeek),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Settings or Logout logic
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: AppColors.dangerRed.withOpacity(0.1),
                foregroundColor: AppColors.dangerRed,
                elevation: 0,
              ),
              child: const Text('Account Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.softLilac),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryDark),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _editName(BuildContext context, WidgetRef ref, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Enter your name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(pregnancyProvider.notifier).updateName(ctrl.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editWeek(BuildContext context, WidgetRef ref, int current) {
    final ctrl = TextEditingController(text: current > 0 ? current.toString() : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Pregnancy Week'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter week (1-42)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final w = int.tryParse(ctrl.text) ?? 0;
              if (w > 0 && w <= 42) {
                ref.read(pregnancyProvider.notifier).updateWeek(w);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
