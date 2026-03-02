// lib/services/storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';

class StorageService {
  static late Box _settings;
  static late Box _healthCache;

  static Future<void> init() async {
    await Hive.initFlutter();
    _settings     = await Hive.openBox(AppConstants.hiveBoxSettings);
    _healthCache  = await Hive.openBox(AppConstants.hiveBoxHealthCache);
  }

  // â”€â”€â”€ Paired device IDs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static String? get pairedWatchId =>
      _settings.get(AppConstants.keyPairedWatchId) as String?;
  static Future<void> setPairedWatchId(String id) =>
      _settings.put(AppConstants.keyPairedWatchId, id);

  static String? get pairedSimId =>
      _settings.get(AppConstants.keyPairedSimId) as String?;
  static Future<void> setPairedSimId(String id) =>
      _settings.put(AppConstants.keyPairedSimId, id);

  // â”€â”€â”€ Pregnancy â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static int? get pregnancyWeek =>
      _settings.get(AppConstants.keyPregnancyWeek) as int?;
  static Future<void> setPregnancyWeek(int week) =>
      _settings.put(AppConstants.keyPregnancyWeek, week);

  static DateTime? get pregnancyStartDate {
    final s = _settings.get(AppConstants.keyPregnancyStartDate) as String?;
    return s != null ? DateTime.tryParse(s) : null;
  }
  static Future<void> setPregnancyStartDate(DateTime date) =>
      _settings.put(AppConstants.keyPregnancyStartDate, date.toIso8601String());

  // â”€â”€â”€ User name â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static String get userName =>
      (_settings.get(AppConstants.keyUserName) as String?) ?? 'Sarah';
  static Future<void> setUserName(String name) =>
      _settings.put(AppConstants.keyUserName, name);

  // â”€â”€â”€ Last known GPS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static double get lastGpsLat =>
      (_healthCache.get(AppConstants.keyLastGpsLat) as double?) ?? 0.0;
  static double get lastGpsLng =>
      (_healthCache.get(AppConstants.keyLastGpsLng) as double?) ?? 0.0;

  static Future<void> setLastGps(double lat, double lng) async {
    await _healthCache.put(AppConstants.keyLastGpsLat, lat);
    await _healthCache.put(AppConstants.keyLastGpsLng, lng);
  }

  // â”€â”€â”€ Last health packet (JSON string) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static String? get lastHealthPacket =>
      _healthCache.get(AppConstants.keyLastHealthPacket) as String?;
  static Future<void> setLastHealthPacket(String json) =>
      _healthCache.put(AppConstants.keyLastHealthPacket, json);

  // â”€â”€â”€ Intelligent Models Data â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static String? get hydrationData =>
      _settings.get(AppConstants.keyHydrationData) as String?;
  static Future<void> setHydrationData(String json) =>
      _settings.put(AppConstants.keyHydrationData, json);

  static String? get sleepData =>
      _settings.get(AppConstants.keySleepData) as String?;
  static Future<void> setSleepData(String json) =>
      _settings.put(AppConstants.keySleepData, json);

  static String? get appointments =>
      _settings.get(AppConstants.keyAppointments) as String?;
  static Future<void> setAppointments(String json) =>
      _settings.put(AppConstants.keyAppointments, json);

  // â”€â”€â”€ Auth / User Profile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static bool get isLoggedIn =>
      (_settings.get(AppConstants.keyIsLoggedIn) as bool?) ?? false;
  static Future<void> setIsLoggedIn(bool v) =>
      _settings.put(AppConstants.keyIsLoggedIn, v);

  static String? get userEmail =>
      _settings.get(AppConstants.keyUserEmail) as String?;
  static Future<void> setUserEmail(String email) =>
      _settings.put(AppConstants.keyUserEmail, email);

  static String? get userPhone =>
      _settings.get(AppConstants.keyUserPhone) as String?;
  static Future<void> setUserPhone(String phone) =>
      _settings.put(AppConstants.keyUserPhone, phone);

  static String? get bloodGroup =>
      _settings.get(AppConstants.keyBloodGroup) as String?;
  static Future<void> setBloodGroup(String bg) =>
      _settings.put(AppConstants.keyBloodGroup, bg);

  static int? get userAge =>
      _settings.get(AppConstants.keyUserAge) as int?;
  static Future<void> setUserAge(int age) =>
      _settings.put(AppConstants.keyUserAge, age);

  static String? get emergencyContact =>
      _settings.get(AppConstants.keyEmergencyContact) as String?;
  static Future<void> setEmergencyContact(String contact) =>
      _settings.put(AppConstants.keyEmergencyContact, contact);

  static String? get passwordHash =>
      _settings.get(AppConstants.keyPasswordHash) as String?;
  static Future<void> setPasswordHash(String hash) =>
      _settings.put(AppConstants.keyPasswordHash, hash);

  static String? get profilePhotoPath =>
      _settings.get(AppConstants.keyProfilePhotoPath) as String?;
  static Future<void> setProfilePhotoPath(String path) =>
      _settings.put(AppConstants.keyProfilePhotoPath, path);

  static bool get biometricEnabled =>
      (_settings.get(AppConstants.keyBiometricEnabled) as bool?) ?? false;
  static Future<void> setBiometricEnabled(bool val) =>
      _settings.put(AppConstants.keyBiometricEnabled, val);

  // â”€â”€â”€ Clear all â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> clearAll() async {
    await _settings.clear();
    await _healthCache.clear();
  }

  // --- Safety Event History ---
  static List<String> get safetyHistory {
    final raw = _settings.get(AppConstants.keySafetyHistory);
    if (raw == null) return [];
    return List<String>.from(raw as List);
  }

  static Future<void> addSafetyEvent(String eventJson) async {
    final list = safetyHistory;
    list.insert(0, eventJson);
    if (list.length > 50) list.removeLast();
    await _settings.put(AppConstants.keySafetyHistory, list);
  }
}
