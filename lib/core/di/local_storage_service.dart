import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
@injectable
class LocalStorageService {
  final SharedPreferences prefs;
  final _tokenController = StreamController<String?>.broadcast();
  final _credsController = StreamController<String?>.broadcast();
  LocalStorageService(this.prefs) {
    _tokenController.add(token);
    _credsController.add(creds);
  }

  static const auth_token = "auth_token";
  static const board_exam_date = 'board_exam_date';

  Future<void> saveToken(String token, String user) async {
    await prefs.setString(auth_token, token);
    await prefs.setString('user_creds', user);
    _tokenController.add(token);
    _credsController.add(user);
  }

  String? get token => prefs.getString(auth_token);
  String? get creds => prefs.getString('user_creds');

  DateTime? get boardExamDate {
    final raw = prefs.getString(board_exam_date);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveBoardExamDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    await prefs.setString(board_exam_date, normalized.toIso8601String());
  }

  Future<void> clearToken() async {
    await prefs.remove(auth_token);
    await prefs.remove('user_creds');
    _tokenController.add(null);
    _credsController.add(null);
  }

  Stream<String?> get tokenStream async* {
    yield token;
    yield* _tokenController.stream;
  }
}
