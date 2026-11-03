import 'package:achievia/const.dart';
import 'package:achievia/core/utils/module_file_access.dart';
import 'package:achievia/presentation/provider/questions/qotd_provider.dart';
import 'package:achievia/core/constants/app_theme.dart';
import 'package:achievia/core/constants/routers/app_router.dart';
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:achievia/presentation/provider/theme/theme_provider.dart';
import 'package:achievia/presentation/widgets/overlays/sleep_reminder_host.dart';
import 'package:achievia/presentation/widgets/overlays/app_lock_gate.dart';
import 'package:flutter/material.dart';
import 'package:achievia/presentation/provider/progress/screentime_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnon);
  await configureDependencies();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(accountCacheResetProvider);
    // Start resolving while the router restores the signed-in screen.
    // Keep the result warm when the dashboard is temporarily off-screen.
    if (ref.watch(activeAccountIdProvider).value != null) {
      ref.watch(qotdStateProvider.select((state) => state.value?.imagePath));
      ref.listen(qotdStateProvider, (previous, next) {
        final imagePath = next.value?.imagePath;
        if (imagePath == null || imagePath == previous?.value?.imagePath) {
          return;
        }
        final uri = resolveModuleFileUri(imagePath);
        if (uri != null &&
            imagePath.isNotEmpty &&
            imagePath.toLowerCase() != 'null') {
          precacheImage(
            NetworkImage(uri.toString()),
            context,
            onError: (_, _) {},
          );
        }
      });
    }
    ref.watch(screentimeProvider.select((value) => value.isLoading));
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Achievia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => AppLockGate(
        child: SleepReminderHost(
          navigatorKey: rootNavigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
