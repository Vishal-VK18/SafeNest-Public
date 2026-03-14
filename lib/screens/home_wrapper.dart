// lib/screens/home_wrapper.dart
//
// HomeWrapper is the landing screen for logged-in users.
// It immediately shows HomeDashboardScreen underneath, then—after the
// first frame is drawn and the route transition is complete—triggers
// biometric authentication exactly once if the user has it enabled.
//
// This avoids calling BiometricPrompt during the splash lifecycle
// (where the Android activity is not yet fully focused/windowed),
// which caused silent failures on most Android OEM skins.

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/biometric_service.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import 'home_dashboard_screen.dart';
import 'auth/login_screen.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  // Ensures authenticate() is called exactly once per navigation
  bool _authChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_authChecked) {
      _authChecked = true;
      // Wait for the first frame (route transition fully settled) before
      // attempting to show the system BiometricPrompt dialog.
      WidgetsBinding.instance.addPostFrameCallback((_) => _runBiometricGate());
    }
  }

  // ── Biometric gate ─────────────────────────────────────────────────────────
  Future<void> _runBiometricGate() async {
    if (!mounted) return;

    final biometricEnabled = StorageService.biometricEnabled;
    developer.log(
      '[HomeWrapper] biometricEnabled=$biometricEnabled',
      name: 'SafeNest.Biometric',
    );

    if (!biometricEnabled) return; // nothing to do

    final result = await BiometricService.instance.checkAndAuthenticate(
      reason: 'Authenticate to open SafeNest',
    );
    developer.log(
      '[HomeWrapper] checkAndAuthenticate result=$result',
      name: 'SafeNest.Biometric',
    );

    if (!mounted) return;

    switch (result) {
      case BiometricResult.success:
        return; // already on HomeDashboardScreen — nothing to do

      case BiometricResult.notAvailable:
        // Auto-disable the toggle so the user isn't locked out
        await StorageService.setBiometricEnabled(false);
        if (!mounted) return;
        await _showInfoDialog(
          title: 'Biometrics Not Available',
          message:
              'Your device does not support biometric authentication. '
              'The biometric lock has been disabled.',
        );

      case BiometricResult.notEnrolled:
        await StorageService.setBiometricEnabled(false);
        if (!mounted) return;
        await _showInfoDialog(
          title: 'No Biometric Registered',
          message:
              'No fingerprint or face has been set up on this device. '
              'Please enrol one in your device Settings, then '
              're-enable the toggle in SafeNest Settings.',
        );

      case BiometricResult.failed:
      case BiometricResult.error:
        if (!mounted) return;
        // Give the user one chance to retry; Skip → go to login
        final retry = await _showRetryDialog();
        if (!mounted) return;
        if (retry == true) {
          // Reset the guard so we try once more
          _authChecked = false;
          _runBiometricGate();
        } else {
          // User skipped → send them to login for safety
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => LoginScreen()),
            (_) => false,
          );
        }
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────
  Future<void> _showInfoDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content:
            Text(message, style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showRetryDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Authentication Failed',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Authentication failed. Please try again or tap Skip '
          'to go to the login screen.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Skip',
                style: GoogleFonts.inter(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Retry', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always show the dashboard — the biometric gate runs on top as a dialog.
    // This means no blocking loading screen is shown; auth feels immediate.
    return HomeDashboardScreen();
  }
}
