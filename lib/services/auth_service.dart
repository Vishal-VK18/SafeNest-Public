import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'storage_service.dart';
import 'firebase_service.dart';

class AuthService {
  AuthService._();

  static final _auth = FirebaseAuth.instance;

  // ─── Login with email + password ─────────────────────────────────────────
  static Future<String?> loginWithCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Save to local storage
      await StorageService.setIsLoggedIn(true);
      await StorageService.setUserEmail(email);
      await StorageService.setUserName(
        cred.user?.displayName ?? email.split('@').first,
      );
      debugPrint('[Auth] Login success: ${cred.user?.email}');
      return null; // null = success
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Login error: ${e.code}');
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return e.message ?? 'Login failed. Please try again.';
      }
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────────
  static Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    DateTime? pregnancyStartDate,
    String? bloodGroup,
    int? age,
    String? emergencyContact,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await cred.user?.updateDisplayName(name);

      // Save to local storage
      await StorageService.setIsLoggedIn(true);
      await StorageService.setUserName(name);
      await StorageService.setUserEmail(email);
      await StorageService.setUserPhone(phone);
      if (bloodGroup != null) await StorageService.setBloodGroup(bloodGroup);
      if (age != null) await StorageService.setUserAge(age);
      if (emergencyContact != null) {
        await StorageService.setEmergencyContact(emergencyContact);
      }
      if (pregnancyStartDate != null) {
        await StorageService.setPregnancyStartDate(pregnancyStartDate);
      }

      // Save to Firestore
      await FirebaseService.instance.saveUserProfile(
        uid: cred.user!.uid,
        name: name,
        email: email,
        phone: phone,
        bloodGroup: bloodGroup ?? '',
        age: age ?? 0,
        emergencyContact: emergencyContact ?? '',
        pregnancyStartDate: pregnancyStartDate,
      );

      debugPrint('[Auth] Register success: ${cred.user?.email}');
      return null; // null = success
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Register error: ${e.code}');
      switch (e.code) {
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        default:
          return e.message ?? 'Registration failed. Please try again.';
      }
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // ─── Google Sign In ───────────────────────────────────────────────────────
  static Future<String?> loginWithGoogle({
    required String name,
    required String email,
  }) async {
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account == null) return 'Google sign in cancelled.';

      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);

      await StorageService.setIsLoggedIn(true);
      await StorageService.setUserName(name);
      await StorageService.setUserEmail(email);

      // Create Firestore profile if new user
      if (cred.additionalUserInfo?.isNewUser == true) {
        await FirebaseService.instance.saveUserProfile(
          uid: cred.user!.uid,
          name: name,
          email: email,
          phone: '',
          bloodGroup: '',
          age: 0,
          emergencyContact: '',
          pregnancyStartDate: null,
        );
      }

      debugPrint('[Auth] Google login success: $email');
      return null;
    } catch (e) {
      debugPrint('[Auth] Google login error: $e');
      return 'Google Sign-In failed. Please try again.';
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    await StorageService.setIsLoggedIn(false);
    // Reset onboarding so slides show again after sign out
    await StorageService.setOnboardingComplete(false);
    // Reset battery permission flag so it asks again
    await StorageService.setBatteryPermissionAsked(false);
    debugPrint('[Auth] Logged out');
  }

  // ─── Password reset ───────────────────────────────────────────────────────
  static Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to send reset email.';
    }
  }

  // ─── OTP (kept for compatibility) ─────────────────────────────────────────
  static void generateOtp(String phone) {
    debugPrint('[Auth] OTP requested for: $phone');
  }

  // ─── Sign out (alias for logout) ──────────────────────────────────────────
  static Future<void> signOut() async => logout();

  // ─── Verify OTP (kept for compatibility) ──────────────────────────────────
  static Future<String?> verifyOtp({
    required String phone,
    required String enteredOtp,
  }) async {
    debugPrint('[Auth] OTP verify requested for: $phone code: $enteredOtp');
    // Demo mode — accept any 6-digit OTP
    if (enteredOtp.length == 6) {
      await StorageService.setIsLoggedIn(true);
      return null; // null = success
    }
    return 'Invalid OTP. Please try again.';
  }

  // ─── Current user ─────────────────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;
}
