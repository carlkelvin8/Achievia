import 'package:achievia/presentation/provider/auth/event/auth_state_provider.dart';
import 'package:achievia/presentation/screens/auth/login_screen.dart';
import 'package:achievia/presentation/screens/auth/onboarding_screen.dart';
import 'package:achievia/presentation/screens/main/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'injection.dart' as di;

void main() {
  runApp(const MyApp());
  di.init();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Achievia',
        debugShowCheckedModeBanner: false,
        home: MainScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/main': (_) => const MainScreen(),
        },
      );
  }
}
