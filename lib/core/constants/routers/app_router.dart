import 'dart:async';

import 'package:achievia/core/utils/billing_helpers.dart';
import 'package:achievia/core/utils/mfa_helpers.dart';
import 'package:achievia/presentation/screens/auth/mfa_challenge_screen.dart';
import 'package:achievia/presentation/screens/settings/mfa_settings_screen.dart';
import 'package:achievia/presentation/screens/billing/payment_status_screen.dart';
import 'package:achievia/presentation/screens/billing/subscription_screen.dart';
import 'package:achievia/core/constants/legal_documents.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/question_bank_navigation.dart';
import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/presentation/screens/auth/email_confirmed_screen.dart';
import 'package:achievia/presentation/screens/auth/forgot_password_screen_handler.dart';
import 'package:achievia/presentation/screens/auth/login_screen.dart';
import 'package:achievia/presentation/screens/auth/signup_screen.dart';
import 'package:achievia/presentation/screens/auth/onboarding_screen.dart';
import 'package:achievia/presentation/screens/legal/legal_document_screen.dart';
import 'package:achievia/presentation/screens/main/about_screen.dart';
import 'package:achievia/presentation/screens/main/attempt_screen.dart';
import 'package:achievia/presentation/screens/main/chat_thread_screen.dart';
import 'package:achievia/presentation/screens/main/exam_screen.dart';
import 'package:achievia/presentation/screens/main/home_screen.dart';
import 'package:achievia/presentation/screens/main/main_screen.dart';
import 'package:achievia/presentation/screens/main/messages_screen.dart';
import 'package:achievia/presentation/screens/main/onboarding_mockboard_screen.dart';
import 'package:achievia/presentation/screens/main/edit_profile_screen.dart';
import 'package:achievia/presentation/screens/main/profile_screen.dart';
import 'package:achievia/presentation/screens/main/reviewers_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/reviewer_category_screen.dart';
import 'package:achievia/presentation/screens/main/summary_screen.dart';
import 'package:achievia/presentation/screens/notifications/notifications_screen.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_subjects_screen.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_topics_screen.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_practice_screen.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_result_screen.dart';
import 'package:achievia/presentation/screens/question_bank/study_mode_screen.dart';
import 'package:achievia/presentation/screens/question_bank/exam_summary_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/completed_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/new_reminder_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/reminder_screen_content.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/scheduled_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/today_screen.dart';
import 'package:achievia/presentation/screens/settings/pomodoro_timer/pomodoro_timer_screen.dart';
import 'package:achievia/presentation/screens/settings/answer_feedback_screen.dart';
import 'package:achievia/presentation/screens/settings/settings_screen.dart';
import 'package:achievia/presentation/screens/admin/daily_motivation_admin_screen.dart';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Root navigator, exposed so app-level overlays can attach above every route.
GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

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
        path: RouteConstants.editProfile,
        builder: (_, _) => const EditProfileScreen(),
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
            return QuestionBankPracticeScreen(
              selection: extra.selection,
              examQuestions: extra.examQuestions,
            );
          }
          return _missingQuestionBankRoute(context);
        },
      ),
      GoRoute(
        path: RouteConstants.questionBankStudy,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is StudyModeArgs) {
            return StudyModeScreen(subject: extra.subject, topic: extra.topic);
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
        path: RouteConstants.questionBankExamSummary,
        builder: (context, state) {
          final args = examSummaryArgsFromRoute(
            extra: state.extra,
            query: state.uri.queryParameters,
          );
          if (args != null) return ExamSummaryScreen(args: args);
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
        path: RouteConstants.privacyPolicy,
        builder: (_, _) => const LegalDocumentScreen(document: privacyPolicy),
      ),
      GoRoute(
        path: RouteConstants.termsOfService,
        builder: (_, _) => const LegalDocumentScreen(document: termsOfService),
      ),
      GoRoute(
        path: RouteConstants.mfaVerify,
        builder: (_, _) => const MfaChallengeScreen(),
      ),
      GoRoute(
        path: RouteConstants.mfaSettings,
        builder: (_, _) => const MfaSettingsScreen(),
      ),
      GoRoute(
        path: RouteConstants.subscription,
        builder: (_, _) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: RouteConstants.paymentStatus,
        builder: (context, state) {
          final order = state.uri.queryParameters['order'];
          if (order == null || order.isEmpty) {
            return const SubscriptionScreen();
          }
          return PaymentStatusScreen(
            orderId: order,
            returnedFromCancel: state.uri.queryParameters['cancelled'] == '1',
          );
        },
      ),
      GoRoute(
        path: RouteConstants.adminDailyMotivation,
        builder: (_, _) => const DailyMotivationAdminScreen(),
      ),
      GoRoute(
        path: RouteConstants.notifications,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteConstants.pomodoroTimer,
        builder: (_, _) => const PomodoroTimerScreen(),
      ),
      GoRoute(
        path: RouteConstants.answerFeedback,
        builder: (_, _) => const AnswerFeedbackScreen(),
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
        path: RouteConstants.preBoardOnboarding,
        builder: (_, _) =>
            const OnboardingMockboardScreen(title: '', isPreBoard: true),
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
        builder: (_, state) => SummaryScreen(attemptNo: state.extra as int?),
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

  // The sign-up form links to both documents, so guests must reach them.
  if (location == RouteConstants.privacyPolicy ||
      location == RouteConstants.termsOfService) {
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

  // Accounts with two-factor authentication must pass the code step before
  // anything else is reachable.
  final mfaTarget = mfaRedirect(
    isLoggedIn: isLoggedIn,
    challengeRequired: isLoggedIn && _mfaChallengeRequired(),
    location: state.uri.path,
  );
  if (mfaTarget != null) return mfaTarget;

  // The checkout page sends the customer back with achievia://callback?
  // payment=success|cancelled&order=<id>. That only opens the status screen,
  // which asks the backend what really happened; it never grants access.
  final paymentReturn = parsePaymentReturn(state.uri);
  if (isLoggedIn && paymentReturn != null) {
    return Uri(
      path: RouteConstants.paymentStatus,
      queryParameters: {
        'order': paymentReturn.orderId,
        if (paymentReturn.cancelled) 'cancelled': '1',
      },
    ).toString();
  }

  if (isLoggedIn &&
      authRefresh.shouldShowEmailConfirmed &&
      state.uri.path != RouteConstants.emailConfirmed) {
    authRefresh.consumeEmailConfirmation();
    return RouteConstants.emailConfirmed;
  }

  return authRedirect(isLoggedIn: isLoggedIn, location: state.uri.path);
}

bool _mfaChallengeRequired() {
  try {
    final level = Supabase.instance.client.auth.mfa
        .getAuthenticatorAssuranceLevel();
    return challengeRequiredFor(
      currentLevel: level.currentLevel?.name,
      nextLevel: level.nextLevel?.name,
    );
  } catch (_) {
    // An unreadable token must never lock a user out of the login screen.
    return false;
  }
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
            onPressed: () => returnToQuestionBankSubjects(context),
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
  bool _isDisposed = false;

  _GoRouterRefreshStream(Stream<AuthState> stream) {
    // Supabase reports failed background token refreshes (for example while
    // offline) as stream errors; they must not surface as unhandled errors.
    _authSubscription = stream.listen(
      _handleAuthState,
      onError: (Object error) {
        debugPrint('Auth state error ignored: ${error.runtimeType}');
      },
    );
    final appLinks = AppLinks();
    _deeplinkSubscription = appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (Object error) {
        debugPrint('Deep link error ignored: ${error.runtimeType}');
      },
    );
    unawaited(_readLatestDeepLink(appLinks));
  }

  bool get shouldShowEmailConfirmed => _shouldShowEmailConfirmed;

  void consumeEmailConfirmation() {
    _shouldShowEmailConfirmed = false;
    _emailConfirmationCallbackReceived = false;
  }

  void _handleAuthState(AuthState state) {
    if (_isDisposed) return;
    if (state.event == AuthChangeEvent.signedIn &&
        state.session != null &&
        _emailConfirmationCallbackReceived) {
      _shouldShowEmailConfirmed = true;
    }
    notifyListeners();
  }

  void _handleDeepLink(Uri uri) {
    if (_isDisposed || !_isAuthCallbackUri(uri)) {
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
    _isDisposed = true;
    _authSubscription.cancel();
    _deeplinkSubscription.cancel();
    super.dispose();
  }
}
