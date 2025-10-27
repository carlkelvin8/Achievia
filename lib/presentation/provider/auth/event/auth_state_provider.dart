import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle()=> state = !state;
  
}

final toggleProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);