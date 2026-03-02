// lib/services/biometric_service.dart
//
// Wraps local_auth for biometric / device-credential authentication.
// Uses typed BiometricResult for specific error messages in callers.

import 'dart:developer' as developer;
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

// ── Result type returned by checkAndAuthenticate() ────────────────────────────
enum BiometricResult {
  success,
  notAvailable,   // no biometric hardware / device not supported
  notEnrolled,    // hardware present but no fingerprint/face registered
  failed,         // user cancelled or matched wrong finger
  error,          // unexpected platform error
}

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  // ── Capability checks ─────────────────────────────────────────────────────
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> availableBiometrics() async {
    try {
      final list = await _auth.getAvailableBiometrics();
      // Debug: log what the device reports
      developer.log(
        '[BiometricService] Available biometrics: $list',
        name: 'SafeNest.Biometric',
      );
      return list;
    } catch (e) {
      developer.log(
        '[BiometricService] getAvailableBiometrics error: $e',
        name: 'SafeNest.Biometric',
      );
      return [];
    }
  }

  // ── One-stop authenticate with typed result ───────────────────────────────
  /// Runs hardware check → enrollment check → authenticate, returning a
  /// typed [BiometricResult] so callers can show specific messages.
  Future<BiometricResult> checkAndAuthenticate({
    String reason = 'Authenticate to open SafeNest',
  }) async {
    try {
      // Step 1: hardware / OS support
      final canCheck    = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      developer.log(
        '[BiometricService] canCheckBiometrics=$canCheck  isDeviceSupported=$isSupported',
        name: 'SafeNest.Biometric',
      );

      if (!canCheck && !isSupported) return BiometricResult.notAvailable;

      // Step 2: enrollment
      final enrolled = await _auth.getAvailableBiometrics();
      developer.log(
        '[BiometricService] enrolled biometrics: $enrolled',
        name: 'SafeNest.Biometric',
      );

      if (enrolled.isEmpty) return BiometricResult.notEnrolled;

      // Step 3: authenticate
      // biometricOnly: false → allows device PIN/pattern as fallback,
      // which is required on some Android OEM skins (Xiaomi MIUI, etc.)
      // where biometricOnly:true silently fails even with enrolled fingerprints.
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allow device credential (PIN/pattern) as fallback
          stickyAuth: true,     // keep prompt alive when user switches apps
        ),
      );

      developer.log(
        '[BiometricService] authenticate result: $ok',
        name: 'SafeNest.Biometric',
      );

      return ok ? BiometricResult.success : BiometricResult.failed;

    } on PlatformException catch (e) {
      developer.log(
        '[BiometricService] PlatformException code=${e.code} msg=${e.message}',
        name: 'SafeNest.Biometric',
      );
      if (e.code == auth_error.notAvailable)           return BiometricResult.notAvailable;
      if (e.code == auth_error.notEnrolled)            return BiometricResult.notEnrolled;
      if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut)   return BiometricResult.failed;
      return BiometricResult.error;
    } catch (e) {
      developer.log(
        '[BiometricService] unexpected error: $e',
        name: 'SafeNest.Biometric',
      );
      return BiometricResult.error;
    }
  }

  // ── Legacy shims kept for backward compat ─────────────────────────────────
  Future<bool> canAuthenticate() async =>
      await canCheckBiometrics() || await isDeviceSupported();

  Future<bool> authenticate({String reason = 'Authenticate to open SafeNest'}) async {
    final result = await checkAndAuthenticate(reason: reason);
    return result == BiometricResult.success;
  }
}
