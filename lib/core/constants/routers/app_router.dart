import 'dart:async';

import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/screens/auth/login_screen.dart';
import 'package:achievia/presentation/screens/auth/onboarding_screen.dart';
import 'package:achievia/presentation/screens/main/about_screen.dart';
import 'package:achievia/presentation/screens/main/attempt_screen.dart';
import 'package:achievia/presentation/screens/main/exam_screen.dart';
import 'package:achievia/presentation/screens/main/home_screen.dart';
import 'package:achievia/presentation/screens/main/main_screen.dart';
import 'package:achievia/presentation/screens/main/messages_screen.dart';
import 'package:achievia/presentation/screens/main/onboarding_mockboard_screen.dart';
import 'package:achievia/presentation/screens/main/profile_screen.dart';
import 'package:achievia/presentation/screens/main/reviewers_screen.dart';
import 'package:achievia/presentation/screens/main/summary_screen.dart';
import 'package:achievia/presentation/screens/notifications/notifications_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/completed_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/new_reminder_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/reminder_screen_content.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/scheduled_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/today_screen.dart';
import 'package:achievia/presentation/screens/settings/examination/examination_screen.dart';
import 'package:achievia/presentation/screens/settings/pomodoro_timer/pomodoro_timer_screen.dart';
import 'package:achievia/presentation/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = _GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  );
  ref.onDispose(authRefresh.dispose);

  final router = GoRouter(
    initialLocation: RouteConstants.main,
    navigatorKey: _rootNavigatorKey,
    refreshListenable: authRefresh,
    redirect: _redirectForAuth,
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('No route defined for ${state.uri.path}')),
    ),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => RouteConstants.main),
      GoRoute(
        path: RouteConstants.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(path: RouteConstants.main, builder: (_, _) => const MainScreen()),
      GoRoute(
        path: RouteConstants.reviewers,
        builder: (_, _) => const ReviewersScreen(),
      ),
      GoRoute(
        path: RouteConstants.messages,
        builder: (_, _) => const MessagesScreen(),
      ),
      GoRoute(path: RouteConstants.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: RouteConstants.profile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteConstants.about,
        builder: (_, _) => const AboutScreen(),
      ),
      GoRoute(
        path: RouteConstants.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteConstants.notifications,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteConstants.examination,
        builder: (_, _) => const ExaminationScreen(),
      ),
      GoRoute(
        path: RouteConstants.pomodoroTimer,
        builder: (_, _) => const PomodoroTimerScreen(),
      ),
      GoRoute(
        path: RouteConstants.reminder,
        builder: (_, _) => const ReminderScreenContent(),
      ),
      GoRoute(
        path: RouteConstants.newReminder,
        builder: (_, _) => const NewReminderScreen(),
      ),
      GoRoute(
        path: RouteConstants.today,
        builder: (_, _) => const TodayScreen(),
      ),
      GoRoute(
        path: RouteConstants.scheduled,
        builder: (_, _) => const ScheduledScreen(),
      ),
      GoRoute(
        path: RouteConstants.completed,
        builder: (_, _) => const CompletedScreen(),
      ),
      GoRoute(
        path: RouteConstants.onboardingQuestions,
        builder: (_, _) => const OnboardingMockboardScreen(title: ''),
      ),
      GoRoute(
        path: RouteConstants.examScreen,
        builder: (_, _) => const ExamScreen(),
      ),
      GoRoute(
        path: RouteConstants.attemptScreen,
        builder: (_, state) => AttemptScreen(attemptId: state.extra as int?),
      ),
      GoRoute(
        path: RouteConstants.summaryScreen,
        builder: (_, _) => const SummaryScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

String? _redirectForAuth(BuildContext context, GoRouterState state) {
  final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
  final location = state.uri.path;
  final isAuthRoute = location == RouteConstants.login || location == RouteConstants.onboarding;

  if (!isLoggedIn && !isAuthRoute) return RouteConstants.login;
  if (isLoggedIn && isAuthRoute) return RouteConstants.main;

  return null;
}

class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
