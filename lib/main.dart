import 'package:achievia/injection.dart';
import 'package:achievia/presentation/provider/auth/event/auth_state_provider.dart';
import 'package:achievia/presentation/screens/auth/login_screen.dart';
import 'package:achievia/presentation/screens/auth/onboarding_screen.dart';
import 'package:achievia/presentation/screens/auth_checker.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => di.sl<AuthStateProvider>()),
      ],
      child: MaterialApp(
        title: 'Achievia',
        debugShowCheckedModeBanner: false,
        home: OnboardingScreen(),
        routes: {
          '/login': (_) => LoginScreen()
        },
      ),
    );
  }
}
