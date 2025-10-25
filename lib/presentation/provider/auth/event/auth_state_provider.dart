import 'package:flutter/material.dart';

class AuthStateProvider with ChangeNotifier {
  bool _isShow = true;
  bool _isLoggedIn = false;
  String _username = '';

  bool get isShow => _isShow;
  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;

  void showText() {
    _isShow = !_isShow;
    notifyListeners();
  }

  void login(String username) {
    _isLoggedIn = true;
    _username = username;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _username = '';
    notifyListeners();
  }
}
