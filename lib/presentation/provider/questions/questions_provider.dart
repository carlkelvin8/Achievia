// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/utils/mock_board_errors.dart';
import 'package:achievia/core/utils/mock_board_progress.dart'
    show MockBoardSession;
import 'dart:async';
import 'package:achievia/presentation/provider/progress/progress_provider.dart';

import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/utils/questions_helpers.dart';
import 'package:achievia/core/utils/snack_bar_utils.dart';
import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/domain/entities/api/home/results_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/entities/widgets/examination_results_entity.dart';
import 'package:achievia/domain/use_cases/questions/questions_use_case.dart';
import 'package:achievia/presentation/provider/questions/mock_board_resume.dart';
import 'package:achievia/presentation/provider/questions/mock_board_review.dart';
import 'package:achievia/presentation/provider/questions/questions_state.dart';
import 'package:achievia/presentation/widgets/dialogs/loading_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

final getQuestions = Provider<QuestionsUseCase>((ref) {
  return sl.get<QuestionsUseCase>();
});

const _mockBoardGenerationTimeout = Duration(seconds: 60);

final useCase = Provider<QuestionsUseCase>((ref) => sl<QuestionsUseCase>());

final getQuestionsProviderState = FutureProvider<List<QuestionsEntity>>((
  ref,
) async {
  final gtQuestions = ref.read(getQuestions);
  try {
    final result = await gtQuestions.getQuestions();
    return result;
  } catch (e) {
    rethrow;
  }
});

// autoDispose so a failed load is retried on the next visit, not cached.
final getResultsProviderState = FutureProvider.autoDispose
    .family<QuizScoreEntity?, int>((ref, attemptNo) async {
      final gtQuestions = ref.read(getQuestions);
      debugPrint('from $attemptNo');
      try {
        final result = await gtQuestions.getGWA(attemptNo);
        return result;
      } catch (e) {
        rethrow;
      }
    });

final recentMockBoardResultsProvider = FutureProvider<List<ExaminationResult>>((
  ref,
) {
  return ref.read(getQuestions).getRecentAttemptResults();
});

final getGeneratedQuestions = FutureProvider<List<QuizItemEntity>>((ref) async {
  final gtQuestions = ref.read(getQuestions);
  try {
    final results = await gtQuestions.getGeneratedQuestions();
    debugPrint(results.toString());
    return results;
  } catch (e) {
    debugPrint(e.toString());
    rethrow;
  }
});
final attemptIdProvider = StateProvider<int?>((ref) => null);

/// The choice index the user picked for each Mock Board question, keyed
/// `'<batchId>:<questionId>'`. Kept after submitting so the Summary screen can
/// show the user's real answers; reset when a new board is generated.
final examSelectedAnswersProvider = StateProvider<Map<String, int>>(
  (ref) => const {},
);

/// Mock Board questions the student marked to revisit, keyed like
/// [examSelectedAnswersProvider]; shown red in the question navigator until
/// unmarked. Reset when a new board is generated.
final examMarkedQuestionsProvider = StateProvider<Set<String>>(
  (ref) => const {},
);

final answeredQuestionsProvider =
    NotifierProvider<ShowUnansweredQuestionsProvider, List<int>>(
      ShowUnansweredQuestionsProvider.new,
    );
final showModalNotifier = NotifierProvider<ShowModalProvider, bool>(
  ShowModalProvider.new,
);
final answerQotProvider =
    NotifierProvider<QuestionsProvider, AnswerQuestionNotifier>(
      QuestionsProvider.new,
    );
final pageController =
    NotifierProvider.autoDispose<PageControllerProvider, PageController>(
      PageControllerProvider.new,
    );
final pageControllerOuter =
    NotifierProvider.autoDispose<OuterPageControllerProvider, PageController>(
      OuterPageControllerProvider.new,
    );
final changeIndexProvider = NotifierProvider.autoDispose<IndexProvider, int>(
  IndexProvider.new,
);

final changeIndexProviderOuter =
    NotifierProvider.autoDispose<IndexProviderOuter, int>(
      IndexProviderOuter.new,
    );

class OuterPageControllerProvider extends Notifier<PageController> {
  @override
  PageController build() {
    // A continued exam opens on the question the student left.
    final controller = PageController(
      initialPage: ref.read(pendingMockBoardProvider)?.questionIndex ?? 0,
    );
    ref.onDispose(controller.dispose);
    return controller;
  }

  bool get _isAttached => state.hasClients;

  Future<void> nextAsOuter(BuildContext context, String debugValue) async {
    if (!_isAttached) return;
    debugPrint("${state.page}");
    debugPrint(debugValue);
    await state.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  Future<void> prev() async {
    if (!_isAttached) return;
    await state.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  Future<void> navigateToPage(int index) async {
    if (!_isAttached) return;
    await state.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }
}

class PageControllerProvider extends Notifier<PageController> {
  QuestionsUseCase get useCases => ref.read(getQuestions);
  bool _isSubmitting = false;
  @override
  PageController build() {
    // A continued exam opens on the subject the student left.
    final controller = PageController(
      initialPage: ref.read(pendingMockBoardProvider)?.subjectIndex ?? 0,
    );
    ref.onDispose(controller.dispose);
    return controller;
  }

  bool get _isAttached => state.hasClients;

  /// Moves to the next batch, or submits the exam when [currentIndex] is the
  /// last batch.
  ///
  /// Returns `true` when the page advanced or the exam was saved, and `false`
  /// when nothing happened (submit failed, already submitting, or the page
  /// controller is not attached) so callers can keep their state intact.
  Future<bool> next(BuildContext context, int length, int currentIndex) async {
    if (currentIndex >= length - 1) {
      if (_isSubmitting) return false;
      _isSubmitting = true;
      try {
        // Taken before submitting: the data source starts a new attempt id
        // once the board is saved. Only for the Summary, so it never blocks
        // the submit.
        MockBoardSession? session;
        try {
          session = useCases.exportMockBoardSession();
        } catch (error) {
          debugPrint('Mock Board not kept for its summary: $error');
        }
        final answers = ref.read(examSelectedAnswersProvider);
        final attemptId = await useCases.submitQuiz();
        if (attemptId <= 0) {
          if (context.mounted) {
            AppToast.showError(
              context,
              'Your exam could not be saved. Please retry.',
            );
          }
          return false;
        }
        // The attempt is already saved at this point; refreshing results is
        // best-effort so a transient failure cannot hide a saved exam.
        if (ref.mounted) {
          // Submitted: nothing is pending, START EXAM is offered again.
          unawaited(ref.read(mockBoardResumeProvider).finish());
          // So this attempt's Summary can be opened again from Profile.
          unawaited(
            keepMockBoardReview(
              ref,
              attemptNo: attemptId,
              session: session,
              selectedAnswers: answers,
            ),
          );
          ref.invalidate(progressProvider);
          ref.invalidate(recentMockBoardResultsProvider);
        }
        try {
          await useCases.getGWA(attemptId);
        } catch (error, stackTrace) {
          debugPrint('Failed to prefetch exam score: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
        if (ref.mounted) {
          ref.read(attemptIdProvider.notifier).state = attemptId;
        }
        if (!context.mounted) return true;
        context.go(RouteConstants.attemptScreen, extra: attemptId);
        return true;
      } catch (error, stackTrace) {
        debugPrint('Mock Boards submit failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (context.mounted) {
          AppToast.showError(
            context,
            'Your exam could not be saved. Please check your connection and '
            'try again.',
          );
        }
        return false;
      } finally {
        _isSubmitting = false;
      }
    }
    if (!_isAttached) return false;
    await state.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
    return true;
  }

  Future<void> prev() async {
    if (!_isAttached) return;
    await state.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  Future<void> navigateToPage(int index) async {
    if (!_isAttached) return;
    await state.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }
}

class ShowUnansweredQuestionsProvider extends Notifier<List<int>> {
  @override
  List<int> build() => [];

  Future<void> isAnswered(int index) async {
    if (state.contains(index)) return;
    state = [...state, index];
  }

  Future<void> resetState() async {
    state = [];
  }
}

class ShowModalProvider extends Notifier<bool> {
  @override
  bool build() => false;

  void showModal() {
    state = !state;
  }
}

class IndexProvider extends Notifier<int> {
  @override
  int build() => ref.read(pendingMockBoardProvider)?.subjectIndex ?? 0;

  void changeIndex(int index) {
    state = index;
  }
}

class IndexProviderOuter extends Notifier<int> {
  @override
  int build() => ref.read(pendingMockBoardProvider)?.questionIndex ?? 0;

  void changeIndex(int index) {
    state = index;
  }
}

class QuestionsProvider extends Notifier<AnswerQuestionNotifier> {
  QuestionsUseCase get useCase => ref.read(getQuestions);
  @override
  AnswerQuestionNotifier build() {
    return AnswerQuestionNotifier(
      quizId: '',
      studentId: '',
      chosenAnswer: '',
      isLoading: false,
    );
  }

  void recordMockBoardAnswer({
    required String subjectName,
    required bool isCorrect,
    int? questionId,
    int? choiceId,
  }) {
    recordAnswer(
      subjectName,
      isCorrect,
      questionId: questionId,
      choiceId: choiceId,
    );
  }

  /// Generates a new board. It replaces any unfinished exam of the same kind
  /// ([isPreBoard]), which can then no longer be continued.
  Future<bool> randomizeQuestion(
    int index,
    BuildContext context, {
    bool isPreBoard = false,
  }) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true);
    var loadingDialogShown = false;
    var prepared = false;
    var failure = MockBoardFailure.internal;

    try {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const LoadingDialog(),
        );
        loadingDialogShown = true;
      }

      final generatedQuestions = await useCase
          .randomizeQuestions(index)
          .timeout(
            _mockBoardGenerationTimeout,
            onTimeout: () => throw TimeoutException(
              'Mock Board generation timed out',
              _mockBoardGenerationTimeout,
            ),
          );
      if (generatedQuestions.isEmpty) {
        throw StateError('No mock board questions were generated');
      }

      ref.invalidate(getGeneratedQuestions);
      // A new board starts clean: no answered badges from a previous exam.
      await ref.read(answeredQuestionsProvider.notifier).resetState();
      ref.read(examSelectedAnswersProvider.notifier).state = const {};
      ref.read(examMarkedQuestionsProvider.notifier).state = const {};
      await ref.read(mockBoardResumeProvider).discard(isPreBoard: isPreBoard);
      prepared = true;
    } catch (error, stackTrace) {
      failure = classifyMockBoardError(error);
      // The technical detail stays in the debug log; users get a safe message.
      debugPrint('Mock Boards generation failed (${failure.name}): $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (loadingDialogShown && context.mounted) {
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) navigator.pop();
      }
      state = state.copyWith(isLoading: false);
    }

    if (!prepared && context.mounted) {
      AppToast.showError(context, mockBoardUserMessage(failure));
    }
    return prepared;
  }
}
