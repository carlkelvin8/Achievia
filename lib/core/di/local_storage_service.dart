import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
@injectable
class LocalStorageService {
  final SharedPreferences prefs;

  LocalStorageService(this.prefs);

  static const auth_token = "auth_token";

  Future<void> saveToken(String token) async {
    await prefs.setString(auth_token, token);
  }

  String? get token => prefs.getString(auth_token);

  Future<void> clearToken()async{
    await prefs.clear();
  }
}
