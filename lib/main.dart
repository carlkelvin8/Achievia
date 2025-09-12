import 'package:achievia/presentation/screens/auth/login_screen.dart';
import 'package:achievia/presentation/screens/auth_checker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Achievia',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
      routes: {},
    );
  }
}

