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
import '../core/constants/route_constants.dart';
import '../services/biometric_service.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../widgets/safe_nest_bottom_navigation.dart';
import '../core/providers/firebase_database_provider.dart';
import '../core/constants/route_constants.dart';
import '../core/services/auth_flow_manager.dart';
import 'caregiver_management_screen.dart';



class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _vitalsAlerts    = true;
  bool _weeklySummaries = false;
  bool _biometricEnabled = false;
  String? _profilePhotoPath;

  @override
  void initState() {
    super.initState();
    _biometricEnabled  = StorageService.biometricEnabled;
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

    // SafeNest Auth Flow Manager
    await ref.read(pregnancyProvider.notifier).clearProfile();
    await AuthFlowManager.onSignOut();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(RouteConstants.login, (route) => false);
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
                          backgroundColor: const Color(0xFFFFC09D).withOpacity(0.15),
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
                                    color: const Color(0xFF181818),
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
                            color: const Color(0xFFFFC09D),
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
                            color: const Color(0xFFFFC09D).withOpacity(0.4))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFFFFC09D), width: 2)),
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
                            color: const Color(0xFFFFC09D).withOpacity(0.4))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFFFFC09D), width: 2)),
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
                      backgroundColor: const Color(0xFF1F3D3D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
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
                        await ref.read(pregnancyProvider.notifier).updatePhoto(pickedPhotoPath!);
                      }
                      if (!sheetCtx.mounted) return;
                      Navigator.pop(sheetCtx);
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
  }

  @override
  Widget build(BuildContext context) {
    final pregnancy = ref.watch(pregnancyProvider);
    _profilePhotoPath = pregnancy.photoLocalPath;
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
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: const SafeNestBottomNavigation(),

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
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            debugPrint('[SafeNest Nav] ← Back tapped: ProfileScreen');
                            debugPrint('[SafeNest Nav] canPop: ${Navigator.of(context).canPop()}');
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else if (Navigator.of(context, rootNavigator: true).canPop()) {
                              Navigator.of(context, rootNavigator: true).pop();
                            } else {
                              Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                                RouteConstants.dashboard,
                                (route) => false,
                              );
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.40),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.50),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Color(0xFF181818),
                              size: 18,
                            ),
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
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    child: Column(
                      children: [
                        // Profile Banner (Editable Hero Card)
                        GestureDetector(
                          onTap: _openEditProfile,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25),
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
                                            width: 64, height: 64, fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 64, height: 64,
                                            color: const Color(0xFFFFC09D).withOpacity(0.3),
                                            child: Center(
                                              child: Text(
                                                pregnancy.userName.isNotEmpty ? pregnancy.userName[0].toUpperCase() : 'S',
                                                style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF181818)),
                                              ),
                                            ),
                                          ),
                                    ),
                                    Positioned(
                                      bottom: 0, right: 0,
                                      child: Container(
                                        width: 16, height: 16,
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pregnancy.userName.isNotEmpty ? pregnancy.userName : 'Sarah',
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF181818),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        pregnancy.pregnancyWeek > 0 ? '${pregnancy.pregnancyWeek} Weeks • Healthy Vitals' : 'Pregnancy Journey',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: const Color(0xFF6B6B6B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.edit_outlined, color: Color(0xFF181818), size: 24),
                              ],
                            ),
                          ),
                        ),
                        
                        // Notifications
                        _buildGroupedCardWrapper(
                          children: [
                            _buildSectionItem(
                              icon: Icons.monitor_heart_outlined,
                              title: 'Vitals Alerts',
                              trailing: _buildToggleSwitch(_vitalsAlerts, (val) => setState(() => _vitalsAlerts = val)),
                            ),
                            _buildSectionItem(
                              icon: Icons.calendar_month_outlined,
                              title: 'Weekly Summaries',
                              trailing: _buildToggleSwitch(_weeklySummaries, (val) => setState(() => _weeklySummaries = val)),
                              showDivider: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Security & Contacts
                        _buildGroupedCardWrapper(
                          children: [
                            _buildSectionItem(
                              icon: Icons.health_and_safety_outlined,
                              title: 'Emergency Contact Access',
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF6B6B6B), size: 16),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => CaregiverManagementScreen()));
                              },
                            ),
                            _buildSectionItem(
                              icon: Icons.face_outlined,
                              title: 'Face ID Unlock',
                              trailing: _buildToggleSwitch(_biometricEnabled, (val) => _onBiometricToggle(val)),
                              showDivider: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Support Pages
                        _buildGroupedCardWrapper(
                          children: [
                            _buildSectionItem(
                              icon: Icons.info_outline_rounded,
                              title: 'How SafeNest Works',
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF6B6B6B), size: 16),
                            ),
                            _buildSectionItem(
                              icon: Icons.help_outline_rounded,
                              title: 'About SafeNest',
                              trailing: Text('v2.4.1', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B6B6B))),
                              showDivider: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Sign Out Button
                        GestureDetector(
                          onTap: _onSignOut,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Sign Out',
                              style: GoogleFonts.inter(
                                fontSize: 16,
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

  Widget _buildGroupedCardWrapper({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSectionItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF181818), size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF181818),
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          if (showDivider)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: const Color(0xFF181818).withOpacity(0.1)),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? const Color(0xFFFFC09D) : Colors.grey[300],
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
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

