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
  bool _vitalsAlerts    = true;
  bool _weeklySummaries = false;
  bool _biometricEnabled = false;
  String? _profilePhotoPath;

  @override
  void initState() {
    super.initState();
    _biometricEnabled  = StorageService.biometricEnabled;
    _profilePhotoPath  = StorageService.profilePhotoPath;
  }

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

  Future<void> _onBiometricToggle(bool val) async {
    await StorageService.setBiometricEnabled(val);
    setState(() => _biometricEnabled = val);

    if (val) {
      final capable = await BiometricService.instance.canAuthenticate();
      if (!mounted) return;
      if (!capable) {
        await StorageService.setBiometricEnabled(false);
        setState(() => _biometricEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Biometric not available on this device.'),
          duration: Duration(seconds: 3),
        ));
        return;
      }
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Biometric unlock enabled. Takes effect on next app launch.'),
        duration: Duration(seconds: 3),
      ));
    }
  }

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
    final contacts = ref.watch(contactsProvider);
    
    // Gradient Background
    final gradientDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFFFC09D), const Color(0xFFFFCACB)],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF8), // creamy
      body: Stack(
        children: [
          // Background Base Map to content-layer styles
          Positioned.fill(
            child: Container(
              decoration: gradientDecoration,
              child: Container(
                color: Colors.white.withOpacity(0.25), // Backdrop blur equivalent
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 40, height: 40,
                            alignment: Alignment.centerLeft,
                            child: const Icon(Icons.arrow_back_ios, color: Color(0xFF181818), size: 20),
                          ),
                        ),
                      ),
                      Text(
                        'Settings',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181818).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24, top: 24, bottom: 24),
                    child: Text(
                      'App Settings',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF181818),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    child: Column(
                      children: [
                        // Profile Banner (Editable)
                        GestureDetector(
                          onTap: _openEditProfile,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20), // "ios"
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: _profilePhotoPath != null
                                        ? Image.file(
                                            File(_profilePhotoPath!),
                                            width: 56, height: 56, fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 56, height: 56,
                                            color: const Color(0xFFFFC09D).withOpacity(0.3),
                                            child: Center(
                                              child: Text(
                                                pregnancy.userName.isNotEmpty ? pregnancy.userName[0].toUpperCase() : '?',
                                                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF181818)),
                                              ),
                                            ),
                                          ),
                                    ),
                                    Positioned(
                                      bottom: 0, right: 0,
                                      child: Container(
                                        width: 14, height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.green[500],
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pregnancy.userName.isNotEmpty ? pregnancy.userName : 'My Profile',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF181818),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${pregnancy.pregnancyWeek > 0 ? '${pregnancy.pregnancyWeek} Weeks' : 'â€”'} â€¢ Healthy Vitals',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Notifications
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSettingToggleTile(
                                'Vitals Alerts',
                                _vitalsAlerts,
                                (val) => setState(() => _vitalsAlerts = val),
                              ),
                              Divider(height: 1, color: Colors.grey[50]),
                              _buildSettingToggleTile(
                                'Weekly Summaries',
                                _weeklySummaries,
                                (val) => setState(() => _weeklySummaries = val),
                              ),
                            ],
                          ),
                        ),
                        
                        // Security & Contacts
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                            ],
                          ),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CaregiverManagementScreen()));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Emergency Contact Access', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF181818))),
                                          const SizedBox(height: 2),
                                          Text('${contacts.length} people have access', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400])),
                                        ],
                                      ),
                                      Icon(Icons.chevron_right, color: Colors.grey[300], size: 24),
                                    ],
                                  ),
                                ),
                              ),
                              Divider(height: 1, color: Colors.grey[50]),
                              _buildSettingToggleTile(
                                'Face ID Unlock',
                                _biometricEnabled,
                                (val) => _onBiometricToggle(val),
                              ),
                            ],
                          ),
                        ),
                        
                        // Support Pages
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildNavTile('How it works', onTap: () {}),
                              Divider(height: 1, color: Colors.grey[50]),
                              _buildNavTile('About SafeNest', trailingText: 'v2.4.1', onTap: () {}),
                            ],
                          ),
                        ),

                        // Sign Out Button
                        GestureDetector(
                          onTap: _onSignOut,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24), // card
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Sign Out',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF181818),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingToggleTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF181818),
            ),
          ),
          // Custom Toggle imitating Tailwind UI
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: value ? const Color(0xFFFFC09D) : Colors.grey[200],
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(String title, {String? trailingText, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181818),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
              )
            else
              Icon(Icons.chevron_right, color: Colors.grey[300], size: 24),
          ],
        ),
      ),
    );
  }
}

