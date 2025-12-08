import 'package:achievia/core/constants/app_theme.dart';
import 'package:achievia/core/constants/routers/app_router.dart';
import 'package:achievia/core/constants/routers/navigation_service.dart';
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/data/models/quiz/questions_dto.dart';
import 'package:achievia/data/models/reviewer/module_dto.dart';
import 'package:achievia/presentation/provider/theme/theme_provider.dart';
import 'package:achievia/presentation/screens/auth/login_screen.dart';
import 'package:achievia/presentation/screens/auth_checker.dart';
import 'package:achievia/presentation/screens/main/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path;
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final appDirectory = await path.getApplicationDocumentsDirectory();
  Hive.init(appDirectory.path);
  Hive.registerAdapter(QuestionsDtoAdapter());
  Hive.registerAdapter(ModuleDtoAdapter());
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
      onGenerateRoute: AppRouter.generateRoute,
      onUnknownRoute: AppRouter.unknownRoute,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: AuthChecker(authenticated: MainScreen(), unauthenticated: LoginScreen()),
    );
  }
}
