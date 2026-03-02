// lib/utils/dev_config.dart
//
// ⚠️  DEVELOPMENT ONLY — flip to false before shipping to production.
//
// When kDevMode == true:
//   • Splash navigates directly to HomeDashboardScreen.
//   • Login screen, HomeWrapper biometric gate, and all auth gating are skipped.
//
// When kDevMode == false:
//   • Full flow: Splash → Login → HomeWrapper (biometric) → HomeDashboardScreen.

// ignore_for_file: constant_identifier_names
const bool kDevMode = true;
