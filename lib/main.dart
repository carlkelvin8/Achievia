import 'package:achievia/const.dart';
import 'package:achievia/core/constants/app_theme.dart';
import 'package:achievia/core/constants/routers/navigation_service.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/presentation/provider/theme/theme_provider.dart';
import 'package:achievia/presentation/screens/auth/onboarding_screen.dart';
import 'package:achievia/presentation/screens/auth_checker.dart';
import 'package:achievia/presentation/screens/main/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnon
  );
  await configureDependencies();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Achievia',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      onGenerateRoute: RouteConstants.generateRoute,
      onUnknownRoute: RouteConstants.unknownRoute,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routes: appRoutes,
      home: AuthChecker(
        authenticated: MainScreen(),
        unauthenticated: OnboardingScreen(),
      ),
    );
  }
}
