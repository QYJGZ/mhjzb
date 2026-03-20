import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';
import '../models/daily_income.dart';
import '../data/default_price_settings.dart';

class StorageService {
  static const _keySettings = 'price_settings';
  static const _keyRecords = 'session_records';
  static const _keyDailyIncomes = 'daily_incomes';

  final SharedPreferences _prefs;
  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Future<PriceSettings> loadSettings() async {
    final raw = _prefs.getString(_keySettings);
    if (raw == null) return defaultPriceSettings();
    try {
      final decoded = jsonDecode(raw);
      final map = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
      return PriceSettings.fromJson(map);
    } catch (_) {
      return PriceSettings();
    }
  }

  Future<void> saveSettings(PriceSettings s) async {
    await _prefs.setString(_keySettings, jsonEncode(s.toJson()));
  }

  Future<List<SessionRecord>> loadRecords() async {
    try {
      final raw = _prefs.getString(_keyRecords);
      if (raw == null) return [];
      final decoded = jsonDecode(raw);
      final list = decoded is List ? decoded : [];
      return list.map((e) {
        final m = e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{};
        return SessionRecord.fromJson(m);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecords(
    List<SessionRecord> records,
    PriceSettings settings,
  ) async {
    final list = records.map((r) => r.toJson(settings)).toList();
    await _prefs.setString(_keyRecords, jsonEncode(list));
  }

  Future<void> appendRecord(
    SessionRecord record,
    PriceSettings settings,
  ) async {
    final list = await loadRecords();
    list.insert(0, record);
    await saveRecords(list, settings);
  }

  Future<List<DailyIncome>> loadDailyIncomes() async {
    try {
      final raw = _prefs.getString(_keyDailyIncomes);
      if (raw == null) return [];
      final decoded = jsonDecode(raw);
      final list = decoded is List ? decoded : [];
      return list
          .map((e) => e is Map
              ? DailyIncome.fromJson(Map<String, dynamic>.from(e))
              : null)
          .whereType<DailyIncome>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDailyIncomes(List<DailyIncome> incomes) async {
    final list = incomes.map((e) => e.toJson()).toList();
    await _prefs.setString(_keyDailyIncomes, jsonEncode(list));
  }
}
