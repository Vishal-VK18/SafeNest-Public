// lib/utils/constants.dart
// BLE UUIDs and application constants for SafeNest

class AppConstants {
  // ─── BLE UUIDs ──────────────────────────────────────────────────────────────
  // Update these to match your actual ESP32-C3 firmware UUIDs
  static const String bleServiceUUID        = '12345678-1234-5678-1234-56789abcdef0';
  static const String bleCharacteristicUUID = '12345678-1234-5678-1234-56789abcdef1';

  // Device name filters
  static const String watchNamePrefix   = 'SafeNest-Watch';
  static const String simUnitNamePrefix = 'SafeNest-SIM';
  static const String safeNestPrefix    = 'SafeNest'; // generic prefix for scan filter

  // ─── Health thresholds ──────────────────────────────────────────────────────
  static const int    heartRateMax      = 120;
  static const int    heartRateMin      = 50;
  static const double tempHighThreshold = 38.0;
  static const double tempLowThreshold  = 35.0;

  // ─── Timing ─────────────────────────────────────────────────────────────────
  static const int heartbeatIntervalSec  = 5;
  static const int autoReconnectDelaySec = 3;
  static const int scanTimeoutSec        = 10;
  static const int fallAlertCountdownSec = 30;

  // ─── Notification IDs ───────────────────────────────────────────────────────
  static const int notifIdFall        = 1001;
  static const int notifIdHeartRate   = 1002;
  static const int notifIdTemperature = 1003;
  static const int notifIdDisconnect  = 1004;
  static const int notifIdSimError    = 1005;

  // ─── Hive box names ─────────────────────────────────────────────────────────
  static const String hiveBoxSettings    = 'settings';
  static const String hiveBoxHealthCache = 'health_cache';

  // ─── Hive keys ──────────────────────────────────────────────────────────────
  static const String keyPairedWatchId    = 'paired_watch_id';
  static const String keyPairedSimId      = 'paired_sim_id';
  static const String keyPregnancyWeek    = 'pregnancy_week';
  static const String keyPregnancyStartDate = 'pregnancy_start_date';
  static const String keyUserName         = 'user_name';
  static const String keyLastHealthPacket = 'last_health_packet';
  static const String keyLastGpsLat       = 'last_gps_lat';
  static const String keyLastGpsLng       = 'last_gps_lng';
  static const String keyHydrationData    = 'hydration_data';
  static const String keySleepData        = 'sleep_data';
  static const String keyAppointments     = 'appointments';

  // Auth / profile
  static const String keyUserEmail        = 'user_email';
  static const String keyUserPhone        = 'user_phone';
  static const String keyIsLoggedIn       = 'is_logged_in';
  static const String keyBloodGroup       = 'blood_group';
  static const String keyUserAge          = 'user_age';
  static const String keyEmergencyContact = 'emergency_contact';
  static const String keyPasswordHash     = 'password_hash';
  static const String keyProfilePhotoPath = 'profile_photo_path';
  static const String keyBiometricEnabled = 'biometric_enabled';
}
