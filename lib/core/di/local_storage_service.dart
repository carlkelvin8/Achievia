import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
@injectable
class LocalStorageService {
  final SharedPreferences prefs;
  final _tokenController = StreamController<String?>.broadcast();

  LocalStorageService(this.prefs) {
    _tokenController.add(token);
  }

  static const auth_token = "auth_token";

  Future<void> saveToken(String token) async {
    await prefs.setString(auth_token, token);
    _tokenController.add(token);
  }

  String? get token => prefs.getString(auth_token);

  Future<void> clearToken() async {
    await prefs.remove(auth_token);
    _tokenController.add(null);
  }

  Stream<String?> get tokenStream async* {
  yield token; 
  yield* _tokenController.stream;
}

}

