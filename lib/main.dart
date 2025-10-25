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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => di.sl<AuthStateProvider>()),
      ],
      child: MaterialApp(
        title: 'Achievia',
        debugShowCheckedModeBanner: false,
        home: Consumer<AuthStateProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.isLoggedIn) {
              return const MainScreen();
            } else {
              return const OnboardingScreen();
            }
          },
        ),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/main': (_) => const MainScreen(),
        },
      ),
    );
  }
}
