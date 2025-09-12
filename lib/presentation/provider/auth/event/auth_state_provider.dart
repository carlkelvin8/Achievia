import 'package:flutter/material.dart';

class AuthStateProvider with ChangeNotifier {
  bool _isShow = true;

  bool get isShow => _isShow;

  void showText() {
    _isShow = !_isShow;
    notifyListeners();
  }
}
