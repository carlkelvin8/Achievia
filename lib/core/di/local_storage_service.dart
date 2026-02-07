import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
@injectable
class LocalStorageService {
  final SharedPreferences prefs;

  static const authToken = "auth_token";

  late final StreamController<String?> _tokenController =
      StreamController<String?>.broadcast(
    onListen: () {
      _tokenController.add(prefs.getString(authToken));
    },
  );

  LocalStorageService(this.prefs);

  String? get token => prefs.getString(authToken);

  Stream<String?> get tokenStream => _tokenController.stream;

  Future<void> saveToken(String token) async {
    await prefs.setString(authToken, token);
    _tokenController.add(token);
  }

  Future<void> clearToken() async {
    await prefs.remove(authToken);
    _tokenController.add(null);
  }
}
