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

  // ─── Paired device IDs ───────────────────────────────────────────────────────
  static String? get pairedWatchId =>
      _settings.get(AppConstants.keyPairedWatchId) as String?;
  static Future<void> setPairedWatchId(String id) =>
      _settings.put(AppConstants.keyPairedWatchId, id);

  static String? get pairedSimId =>
      _settings.get(AppConstants.keyPairedSimId) as String?;
  static Future<void> setPairedSimId(String id) =>
      _settings.put(AppConstants.keyPairedSimId, id);

  // ─── Pregnancy ───────────────────────────────────────────────────────────────
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

  // ─── User name ─────────────────────────────────────────────────────────────
  static String get userName =>
      (_settings.get(AppConstants.keyUserName) as String?) ?? 'Sarah';
  static Future<void> setUserName(String name) =>
      _settings.put(AppConstants.keyUserName, name);

  // ─── Last known GPS ──────────────────────────────────────────────────────────
  static double get lastGpsLat =>
      (_healthCache.get(AppConstants.keyLastGpsLat) as double?) ?? 0.0;
  static double get lastGpsLng =>
      (_healthCache.get(AppConstants.keyLastGpsLng) as double?) ?? 0.0;

  static Future<void> setLastGps(double lat, double lng) async {
    await _healthCache.put(AppConstants.keyLastGpsLat, lat);
    await _healthCache.put(AppConstants.keyLastGpsLng, lng);
  }

  // ─── Last health packet (JSON string) ───────────────────────────────────────
  static String? get lastHealthPacket =>
      _healthCache.get(AppConstants.keyLastHealthPacket) as String?;
  static Future<void> setLastHealthPacket(String json) =>
      _healthCache.put(AppConstants.keyLastHealthPacket, json);

  // ─── Clear all ─────────────────────────────────────────────────────────────
  static Future<void> clearAll() async {
    await _settings.clear();
    await _healthCache.clear();
  }
}
