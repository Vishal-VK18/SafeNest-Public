// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/providers.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import 'caregiver_management_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Local toggle states (notifications — visual only)
  bool _vitalsAlerts    = true;
  bool _weeklySummaries = false;

  // Biometric — backed by StorageService
  bool _biometricEnabled = false;

  // Profile photo path
  String? _profilePhotoPath;

  @override
  void initState() {
    super.initState();
    _biometricEnabled  = StorageService.biometricEnabled;
    _profilePhotoPath  = StorageService.profilePhotoPath;
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────────
  Future<void> _onSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'You will be returned to the login screen. Your health data will be kept.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign Out',
                style: GoogleFonts.inter(
                    color: AppColors.dangerRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await AuthService.signOut();
    try { await GoogleSignIn().signOut(); } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // ── Biometric toggle ─────────────────────────────────────────────────────────
  // Toggle only saves the enabled flag.
  // Authentication is only triggered at app launch (splash_screen.dart).
  Future<void> _onBiometricToggle(bool val) async {
    await StorageService.setBiometricEnabled(val);
    setState(() => _biometricEnabled = val);

    if (val) {
      // Quick capability check — inform user if device can't do biometrics,
      // but do NOT call authenticate() here.
      final capable = await BiometricService.instance.canAuthenticate();
      if (!mounted) return;
      if (!capable) {
        // Device not capable — revert the flag
        await StorageService.setBiometricEnabled(false);
        setState(() => _biometricEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Biometric not available on this device.'),
          duration: Duration(seconds: 3),
        ));
        return;
      }
      // Check enrollment
      final enrolled = await BiometricService.instance.availableBiometrics();
      if (!mounted) return;
      if (enrolled.isEmpty) {
        await StorageService.setBiometricEnabled(false);
        setState(() => _biometricEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'No biometric enrolled. Enrol a fingerprint/face in device Settings first.',
          ),
          duration: Duration(seconds: 4),
        ));
        return;
      }
      // All good
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Biometric unlock enabled. Takes effect on next app launch.'),
        duration: Duration(seconds: 3),
      ));
    }
  }

  // ── Edit profile bottom sheet ─────────────────────────────────────────────────
  Future<void> _openEditProfile() async {
    final pregnancy        = ref.read(pregnancyProvider);
    final nameCtrl         = TextEditingController(text: pregnancy.userName);
    final ageCtrl          = TextEditingController(
        text: StorageService.userAge?.toString() ?? '');
    String? pickedPhotoPath = _profilePhotoPath;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (sheetCtx, setSheetState) {
          Future<void> pickImage() async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(
                source: ImageSource.gallery, imageQuality: 85);
            if (picked != null) {
              setSheetState(() => pickedPhotoPath = picked.path);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Edit Profile',
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),

                // Avatar picker
                Center(
                  child: GestureDetector(
                    onTap: pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          backgroundImage: pickedPhotoPath != null
                              ? FileImage(File(pickedPhotoPath!))
                              : null,
                          child: pickedPhotoPath == null
                              ? Text(
                                  pregnancy.userName.isNotEmpty
                                      ? pregnancy.userName[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.inter(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Full Name
                Text('Full Name',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600])),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Your full name',
                    hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: AppColors.primary.withOpacity(0.3))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // Age
                Text('Age',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600])),
                const SizedBox(height: 6),
                TextField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Your age',
                    hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: AppColors.primary.withOpacity(0.3))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isNotEmpty) {
                        await ref
                            .read(pregnancyProvider.notifier)
                            .updateName(name);
                      }
                      final age = int.tryParse(ageCtrl.text.trim());
                      if (age != null && age > 0 && age < 120) {
                        await StorageService.setUserAge(age);
                      }
                      if (pickedPhotoPath != null) {
                        await StorageService.setProfilePhotoPath(
                            pickedPhotoPath!);
                      }
                      if (!sheetCtx.mounted) return;
                      Navigator.pop(sheetCtx);
                      // Refresh photo in parent
                      setState(() => _profilePhotoPath = pickedPhotoPath);
                    },
                    child: Text('Save Changes',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
    nameCtrl.dispose();
    ageCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pregnancy = ref.watch(pregnancyProvider);
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    // Emergency contact from storage
    final emergencyContact = StorageService.emergencyContact;
    final emergencyPhone   = StorageService.userPhone; // phone saved during registration

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.chevron_left, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              )
            : const SizedBox.shrink(),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
        centerTitle: true,
        actions: const [SizedBox(width: 48)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Settings',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),

            // ── Profile Preview Card ──────────────────────────────────────────
            GestureDetector(
              onTap: _openEditProfile,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          backgroundImage: _profilePhotoPath != null
                              ? FileImage(File(_profilePhotoPath!))
                              : null,
                          child: _profilePhotoPath == null
                              ? Text(
                                  pregnancy.userName.isNotEmpty
                                      ? pregnancy.userName[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF18161C) : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.edit, size: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pregnancy.userName.isNotEmpty
                                ? pregnancy.userName
                                : 'Tap to edit profile',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pregnancy.pregnancyWeek > 0 ? '${pregnancy.pregnancyWeek} Weeks' : '—'} • Tap to edit',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[300]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Notifications ─────────────────────────────────────────────────
            _buildSectionHeader(Icons.notifications_active_outlined, 'Notifications'),
            _buildSettingsGroup([
              _buildToggleRow(
                icon: Icons.favorite_border,
                title: 'Vitals Alerts',
                value: _vitalsAlerts,
                onChanged: (val) => setState(() => _vitalsAlerts = val),
              ),
              _buildToggleRow(
                icon: Icons.history,
                title: 'Weekly Summaries',
                value: _weeklySummaries,
                onChanged: (val) => setState(() => _weeklySummaries = val),
              ),
            ]),
            const SizedBox(height: 24),

            // ── Privacy & Security ─────────────────────────────────────────────
            _buildSectionHeader(Icons.security, 'Privacy & Security'),
            _buildSettingsGroup([
              // Emergency contact — shows real name from storage
              _buildNavigationRow(
                icon: Icons.lock_person_outlined,
                title: 'Emergency Contact',
                subtitle: emergencyContact != null && emergencyContact.isNotEmpty
                    ? emergencyContact
                    : (emergencyPhone != null && emergencyPhone.isNotEmpty
                        ? emergencyPhone
                        : 'Add emergency contact'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CaregiverManagementScreen()),
                  );
                },
              ),
              _buildAsyncToggleRow(
                icon: Icons.fingerprint,
                title: 'Face ID / Fingerprint',
                subtitle: _biometricEnabled ? 'Enabled' : 'Disabled',
                value: _biometricEnabled,
                onChanged: _onBiometricToggle,
              ),
            ]),
            const SizedBox(height: 24),

            // ── Support ────────────────────────────────────────────────────────
            _buildSectionHeader(Icons.info_outline, 'Support'),
            _buildSettingsGroup([
              _buildNavigationRow(
                icon: Icons.help_outline,
                title: 'How it works',
                onTap: () {},
              ),
              _buildNavigationRow(
                icon: Icons.description_outlined,
                title: 'About SafeNest',
                trailingText: 'v2.4.1',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 32),

            // ── Sign Out ───────────────────────────────────────────────────────
            InkWell(
              onTap: _onSignOut,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppColors.dangerRed.withOpacity(0.2), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Sign Out',
                  style: GoogleFonts.inter(
                    color: AppColors.dangerRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'ENSURING SAFE JOURNEY SINCE 2024',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  // ── Shared helper builders ────────────────────────────────────────────────────
  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          if (index == children.length - 1) return child;
          return Column(children: [
            child,
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.grey[700]! : Colors.grey[100]!,
              indent: 64,
              endIndent: 16,
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }

  // Same as toggle but with subtitle and async onChanged
  Widget _buildAsyncToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Future<void> Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.grey[400])),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRow({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryDark, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.grey[400])),
                  ],
                ],
              ),
            ),
            if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(trailingText,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500)),
              )
            else
              Icon(Icons.chevron_right, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
