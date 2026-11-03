import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
@injectable
class LocalStorageService {
  final SharedPreferences prefs;
  final _tokenController = StreamController<String?>.broadcast();
  LocalStorageService(this.prefs) {
    _tokenController.add(token);
  }

  static const authToken = "auth_token";
  static const _boardExamDateBase = 'board_exam_date';
  String get _boardExamDateKey =>
      '${_boardExamDateBase}_${Supabase.instance.client.auth.currentUser?.id ?? "guest"}';

  Future<void> saveToken(String token) async {
    await prefs.setString(authToken, token);
    _tokenController.add(token);
  }

  String? get token => prefs.getString(authToken);

  DateTime? get boardExamDate {
    final raw = prefs.getString(_boardExamDateKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveBoardExamDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    await prefs.setString(_boardExamDateKey, normalized.toIso8601String());
  }

  static const _appLockBase = 'app_lock_enabled';

  /// Biometric app lock is chosen per account on this device.
  bool isAppLockEnabled(String userId) =>
      prefs.getBool('${_appLockBase}_$userId') ?? false;

  Future<void> setAppLockEnabled(String userId, bool enabled) async {
    final key = '${_appLockBase}_$userId';
    if (enabled) {
      await prefs.setBool(key, true);
    } else {
      await prefs.remove(key);
    }
  }

  static const _dailyMotivationCacheKey = 'daily_motivation_cache';

  /// JSON of the motivation resolved for a calendar day (shared by accounts).
  String? get dailyMotivationCache => prefs.getString(_dailyMotivationCacheKey);

  Future<void> saveDailyMotivationCache(String? json) async {
    if (json == null) {
      await prefs.remove(_dailyMotivationCacheKey);
    } else {
      await prefs.setString(_dailyMotivationCacheKey, json);
    }
  }

  Future<void> clearToken() async {
    await prefs.remove(authToken);
    // Legacy key from versions that stored user details in plain preferences.
    await prefs.remove('user_creds');
    _tokenController.add(null);
  }

  Stream<String?> get tokenStream async* {
    yield token;
    yield* _tokenController.stream;
  }
}
