import 'dart:async';

import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/presentation/screens/auth/email_confirmed_screen.dart';
import 'package:achievia/presentation/screens/auth/forgot_password_screen_handler.dart';
import 'package:achievia/presentation/screens/auth/login_screen.dart';
import 'package:achievia/presentation/screens/auth/signup_screen.dart';
import 'package:achievia/presentation/screens/auth/onboarding_screen.dart';
import 'package:achievia/presentation/screens/main/about_screen.dart';
import 'package:achievia/presentation/screens/main/attempt_screen.dart';
import 'package:achievia/presentation/screens/main/chat_thread_screen.dart';
import 'package:achievia/presentation/screens/main/exam_screen.dart';
import 'package:achievia/presentation/screens/main/home_screen.dart';
import 'package:achievia/presentation/screens/main/main_screen.dart';
import 'package:achievia/presentation/screens/main/messages_screen.dart';
import 'package:achievia/presentation/screens/main/onboarding_mockboard_screen.dart';
import 'package:achievia/presentation/screens/main/profile_screen.dart';
import 'package:achievia/presentation/screens/main/reviewers_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/reviewer_category_screen.dart';
import 'package:achievia/presentation/screens/main/summary_screen.dart';
import 'package:achievia/presentation/screens/notifications/notifications_screen.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_subjects_screen.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_topics_screen.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_practice_screen.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_result_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/completed_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/new_reminder_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/reminder_screen_content.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/scheduled_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/today_screen.dart';
import 'package:achievia/presentation/screens/settings/examination/examination_screen.dart';
import 'package:achievia/presentation/screens/settings/pomodoro_timer/pomodoro_timer_screen.dart';
import 'package:achievia/presentation/screens/settings/settings_screen.dart';

import 'package:app_links/app_links.dart';
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
    // IMPORTANT FIX: DO NOT lock to /main
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    refreshListenable: authRefresh,

    redirect: (_, state) => _redirectForAuth(state, authRefresh: authRefresh),

    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('No route defined for ${state.uri.path}')),
    ),

    routes: [
      GoRoute(path: '/', redirect: (_, _) => RouteConstants.main),

      // AUTH
      GoRoute(
        path: RouteConstants.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.signUp,
        builder: (_, _) => const SignupScreen(),
      ),
      GoRoute(
        path: RouteConstants.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteConstants.emailConfirmed,
        builder: (_, _) => const EmailConfirmedScreen(),
      ),

      // MAIN
      GoRoute(path: RouteConstants.main, builder: (_, _) => const MainScreen()),
      GoRoute(path: RouteConstants.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: RouteConstants.profile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteConstants.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreenHandler(),
      ),
      GoRoute(
        path: RouteConstants.reviewers,
        builder: (_, _) => const ReviewersScreen(),
      ),
      GoRoute(
        path: RouteConstants.motherNotes,
        builder: (_, _) => const MotherNotesScreen(),
      ),
      GoRoute(
        path: RouteConstants.questionBank,
        builder: (_, _) => const QuestionBankScreen(),
      ),
      GoRoute(
        path: RouteConstants.questionBankSubjects,
        builder: (_, _) => const QuestionBankSubjectsScreen(),
      ),
      GoRoute(
        path: RouteConstants.questionBankTopics,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is QuestionBankTopicArgs) {
            return QuestionBankTopicsScreen(subject: extra.subject);
          }
          return _missingQuestionBankRoute(context);
        },
      ),
      GoRoute(
        path: RouteConstants.questionBankPractice,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is QuestionBankPracticeArgs) {
            return QuestionBankPracticeScreen(selection: extra.selection);
          }
          return _missingQuestionBankRoute(context);
        },
      ),
      GoRoute(
        path: RouteConstants.questionBankResults,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is QuestionBankResultArgs) {
            return QuestionBankResultScreen(args: extra);
          }
          return _missingQuestionBankRoute(context);
        },
      ),
      GoRoute(
        path: RouteConstants.supplementals,
        builder: (_, _) => const SupplementalsScreen(),
      ),
      GoRoute(
        path: RouteConstants.messages,
        builder: (_, _) => const MessagesScreen(),
      ),
      GoRoute(
        path: RouteConstants.chatThread,
        builder: (context, state) {
          final extra = state.extra;

          if (extra is! ChatConversationEntity) {
            return Scaffold(
              appBar: AppBar(title: const Text('Chat')),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Conversation not found'),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go(RouteConstants.messages),
                      child: const Text('Back to messages'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ChatThreadScreen(conversation: extra);
        },
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

String? authRedirect({required bool isLoggedIn, required String location}) {
  const guestRoutes = <String>{
    RouteConstants.onboarding,
    RouteConstants.login,
    RouteConstants.signUp,
  };

  if (location == RouteConstants.forgotPassword) {
    return null;
  }

  if (location == RouteConstants.emailConfirmed) {
    return null;
  }

  if (!isLoggedIn) {
    return guestRoutes.contains(location) ? null : RouteConstants.login;
  }

  return guestRoutes.contains(location) ? RouteConstants.main : null;
}

String? _redirectForAuth(
  GoRouterState state, {
  required _GoRouterRefreshStream authRefresh,
}) {
  final session = Supabase.instance.client.auth.currentSession;
  final isLoggedIn = session != null && !session.isExpired;

  if (isLoggedIn &&
      authRefresh.shouldShowEmailConfirmed &&
      state.uri.path != RouteConstants.emailConfirmed) {
    authRefresh.consumeEmailConfirmation();
    return RouteConstants.emailConfirmed;
  }

  return authRedirect(isLoggedIn: isLoggedIn, location: state.uri.path);
}

Widget _missingQuestionBankRoute(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Question Bank')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Content unavailable'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go(RouteConstants.questionBankSubjects),
            child: const Text('Back to subjects'),
          ),
        ],
      ),
    ),
  );
}

class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<AuthState> _authSubscription;
  late final StreamSubscription<Uri> _deeplinkSubscription;
  bool _emailConfirmationCallbackReceived = false;
  bool _shouldShowEmailConfirmed = false;

  _GoRouterRefreshStream(Stream<AuthState> stream) {
    _authSubscription = stream.listen(_handleAuthState);
    final appLinks = AppLinks();
    _deeplinkSubscription = appLinks.uriLinkStream.listen(_handleDeepLink);
    unawaited(_readLatestDeepLink(appLinks));
  }

  bool get shouldShowEmailConfirmed => _shouldShowEmailConfirmed;

  void consumeEmailConfirmation() {
    _shouldShowEmailConfirmed = false;
    _emailConfirmationCallbackReceived = false;
  }

  void _handleAuthState(AuthState state) {
    if (state.event == AuthChangeEvent.signedIn &&
        state.session != null &&
        _emailConfirmationCallbackReceived) {
      _shouldShowEmailConfirmed = true;
    }
    notifyListeners();
  }

  void _handleDeepLink(Uri uri) {
    if (!_isAuthCallbackUri(uri)) {
      return;
    }

    _emailConfirmationCallbackReceived = true;
    if (Supabase.instance.client.auth.currentSession != null) {
      _shouldShowEmailConfirmed = true;
    }
    notifyListeners();
  }

  Future<void> _readLatestDeepLink(AppLinks appLinks) async {
    try {
      final uri = await appLinks.getLatestLink();
      if (uri != null) {
        _handleDeepLink(uri);
      }
    } catch (_) {
      // Supabase's own observer remains responsible for exchanging the link.
    }
  }

  bool _isAuthCallbackUri(Uri uri) {
    if (uri.scheme != 'achievia' || uri.host != 'callback') {
      return false;
    }

    return uri.queryParameters.containsKey('code') ||
        uri.fragment.contains('access_token');
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _deeplinkSubscription.cancel();
    super.dispose();
  }
}
