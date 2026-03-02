// lib/services/auth_service.dart
//
// AuthService: handles credential storage, validation, hashing, and session.
// All credentials are stored in Hive via StorageService.
// Passwords are SHA-256 hashed before storage — never stored plaintext.

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'storage_service.dart';

class AuthService {
  // ─── Singleton ─────────────────────────────────────────────────────────────
  AuthService._();
  static final AuthService instance = AuthService._();

  // ─── Password Hashing ──────────────────────────────────────────────────────
  static String hashPassword(String raw) {
    final bytes = utf8.encode(raw.trim());
    return sha256.convert(bytes).toString();
  }

  // ─── Registration ─────────────────────────────────────────────────────────
  /// Saves user credentials on Create Account.
  /// Returns null on success, or an error string on failure.
  static Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    DateTime? pregnancyStartDate,
    String bloodGroup = 'B+',
    int? age,
    String? emergencyContact,
  }) async {
    // Store everything
    await StorageService.setUserName(name);
    await StorageService.setUserEmail(email);
    await StorageService.setUserPhone(phone);
    await StorageService.setPasswordHash(hashPassword(password));
    await StorageService.setBloodGroup(bloodGroup);
    if (pregnancyStartDate != null) {
      await StorageService.setPregnancyStartDate(pregnancyStartDate);
    }
    if (age != null) {
      await StorageService.setUserAge(age);
    }
    if (emergencyContact != null && emergencyContact.trim().isNotEmpty) {
      await StorageService.setEmergencyContact(emergencyContact);
    }
    await StorageService.setIsLoggedIn(true);
    return null;
  }

  // ─── Login with email+password ─────────────────────────────────────────────
  /// Returns null on success, or error message string on failure.
  static Future<String?> loginWithCredentials({
    required String email,
    required String password,
  }) async {
    // TODO: REMOVE DEV LOGIN BEFORE PRODUCTION
    // ── Temporary development bypass ──────────────────────────────────────────
    const _devEmail    = 'chathurvitha@gmail.com';
    const _devPassword = 'vitha2005';
    if (email.toLowerCase().trim() == _devEmail &&
        password == _devPassword) {
      await StorageService.setIsLoggedIn(true);
      await StorageService.setUserEmail(_devEmail);
      return null; // dev login success
    }
    // ── End dev bypass ────────────────────────────────────────────────────────

    final storedEmail = StorageService.userEmail;
    final storedHash  = StorageService.passwordHash;

    // No account registered yet
    if (storedEmail == null || storedHash == null) {
      return 'No account found. Please create an account first.';
    }

    if (storedEmail.toLowerCase().trim() != email.toLowerCase().trim()) {
      return 'No account found for this email address.';
    }

    if (storedHash != hashPassword(password)) {
      return 'Incorrect password. Please try again.';
    }

    await StorageService.setIsLoggedIn(true);
    return null;
  }

  // ─── Google Sign-In (data persistence) ────────────────────────────────────
  /// Called after successful Google Sign-In to persist user data.
  static Future<void> loginWithGoogle({
    required String name,
    required String email,
  }) async {
    await StorageService.setUserName(name);
    await StorageService.setUserEmail(email);
    await StorageService.setIsLoggedIn(true);
  }

  // ─── OTP ──────────────────────────────────────────────────────────────────
  static String _pendingOtp = '';
  static String _pendingPhone = '';

  /// Generates a 6-digit OTP, stores it temporarily, and returns it for
  /// simulated dispatch (log to console). In production, send via SMS API.
  static String generateOtp(String phone) {
    final otp = (100000 + Random().nextInt(900000)).toString();
    _pendingOtp   = otp;
    _pendingPhone = phone;
    // ignore: avoid_print
    print('[SafeNest OTP] Code for $phone: $otp');
    return otp;
  }

  /// Validates the submitted OTP against the pending one.
  /// Returns null on match, error string on failure.
  static Future<String?> verifyOtp({
    required String phone,
    required String enteredOtp,
  }) async {
    if (_pendingPhone != phone) return 'Phone number mismatch.';
    if (_pendingOtp.isEmpty)    return 'No OTP was generated. Please request a new one.';
    if (_pendingOtp != enteredOtp.trim()) return 'Incorrect OTP. Please try again.';

    // OTP valid — persist session
    _pendingOtp   = '';
    _pendingPhone = '';
    await StorageService.setUserPhone(phone);
    await StorageService.setIsLoggedIn(true);
    return null;
  }

  // ─── Sign Out ──────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    await StorageService.setIsLoggedIn(false);
    // Keep pregnancy, name and health data — only clear session flag
  }

  // ─── Session check ─────────────────────────────────────────────────────────
  static bool get isLoggedIn => StorageService.isLoggedIn;
}
