import 'package:achievia/core/utils/questions_helpers.dart'
    show resetMockBoardAnswers;
import 'package:achievia/presentation/provider/billing/billing_provider.dart'
    show accessStatusProvider;
import 'package:achievia/presentation/provider/chat/chat_provider.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:achievia/presentation/provider/notifications/notifications_provider.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart'
    show timerProvider, pomodoroProvider;
import 'package:achievia/presentation/provider/questions/mock_board_resume.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/provider/settings/settings_provider.dart'
    show sleepTimeProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final activeAccountIdProvider = StreamProvider<String?>((ref) async* {
  final auth = Supabase.instance.client.auth;
  yield auth.currentUser?.id;
  yield* auth.onAuthStateChange
      .map((event) => event.session?.user.id)
      .distinct();
});

/// Clear private caches without destroying the router or OTP recovery form.
final accountCacheResetProvider = Provider<void>((ref) {
  String? lastId;
  var initialized = false;
  ref.listen(activeAccountIdProvider, (_, next) {
    if (next is! AsyncData<String?>) return;
    final id = next.value;
    if (initialized && id == lastId) return;
    initialized = true;
    lastId = id;
    resetMockBoardAnswers();
    ref.invalidate(profileProvider);
    ref.invalidate(accessStatusProvider);
    ref.invalidate(boardExamDateProvider);
    ref.invalidate(chatConversationsProvider);
    ref.invalidate(chatPeopleSearchProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(timerProvider);
    ref.invalidate(pomodoroProvider);
    ref.invalidate(getResultsProviderState);
    ref.invalidate(recentMockBoardResultsProvider);
    ref.invalidate(recentQuestionBankAttemptsProvider);
    ref.invalidate(recentSubjectExamAttemptsProvider);
    ref.invalidate(questionBankSessionProvider);
    ref.invalidate(sleepTimeProvider);
    ref.invalidate(attemptIdProvider);
    ref.invalidate(examSelectedAnswersProvider);
    ref.invalidate(examMarkedQuestionsProvider);
    ref.invalidate(answeredQuestionsProvider);
    // A pending exam belongs to its account; it stays saved on the device and
    // is offered again when that account signs back in.
    ref.invalidate(pendingMockBoardProvider);
    ref.invalidate(activeMockBoardIsPreBoardProvider);
  }, fireImmediately: true);
});
