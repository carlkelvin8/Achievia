import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@singleton
class LocalStorageService {
  final SharedPreferences prefs;

  LocalStorageService(this.prefs);
}
