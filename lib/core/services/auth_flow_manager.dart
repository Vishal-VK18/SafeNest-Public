import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/route_constants.dart';
import '../../utils/dev_config.dart';

class AuthFlowManager {
  static const String _boxName = 'auth_prefs';
  static const String _hasSeenGetStarted = 'has_seen_get_started';
  static const String _isLoggedIn = 'is_logged_in';

  /// Call this on app launch to determine where to navigate
  static Future<String> getInitialRoute() async {
    // Development Mode Bypass
    if (kDevMode) {
      debugPrint('[SafeNest Auth] DEV BYPASS ACTIVE — going to dashboard');
      return RouteConstants.dashboard;
    }

    try {
      final box = Hive.box(_boxName);

      final bool isLoggedIn = box.get(_isLoggedIn, defaultValue: false);
      final bool hasSeenGetStarted = box.get(_hasSeenGetStarted, defaultValue: false);

      debugPrint('[SafeNest Auth] isLoggedIn: $isLoggedIn');
      debugPrint('[SafeNest Auth] hasSeenGetStarted: $hasSeenGetStarted');

      // Verify with Firebase Auth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      debugPrint('[SafeNest Auth] Firebase currentUser: ${firebaseUser?.uid ?? "null"}');

      // 1. If not logged in & never seen get started -> Get Started
      if (firebaseUser == null && !hasSeenGetStarted) {
        return RouteConstants.getStarted;
      }

      // 2. If not logged in & has seen get started -> Login
      if (firebaseUser == null) {
        return RouteConstants.login;
      }

      // 3. Logged in -> Dashboard
      return RouteConstants.dashboard;
    } catch (e) {
      debugPrint('[SafeNest Auth] getInitialRoute error: $e');
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) return RouteConstants.dashboard;
      return RouteConstants.getStarted;
    }
  }

  /// Call when user successfully logs in or creates account
  static Future<void> onLoginSuccess() async {
    final box = Hive.box(_boxName);
    await box.put(_isLoggedIn, true);
    await box.put(_hasSeenGetStarted, true);
    debugPrint('[SafeNest Auth] ✅ Login success flags saved');
  }

  /// Call when user completes all steps of onboarding
  static Future<void> onGetStartedCompleted() async {
    final box = Hive.box(_boxName);
    await box.put(_hasSeenGetStarted, true);
    debugPrint('[SafeNest Auth] ✅ Onboarding completed flag saved');
  }

  /// Call when user signs out
  static Future<void> onSignOut() async {
    final box = Hive.box(_boxName);
    await box.put(_isLoggedIn, false);
    // Reset this so they see the slides again on next app launch after signing out
    await box.put(_hasSeenGetStarted, false);
    debugPrint('[SafeNest Auth] ✅ Sign out flags updated & onboarding reset');
  }

  /// Check if user is currently logged in
  static Future<bool> checkIsLoggedIn() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    return firebaseUser != null;
  }
}
