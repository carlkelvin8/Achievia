import 'package:achievia/core/utils/recent_results.dart' show examHistoryLimit;
import 'package:achievia/core/utils/question_bank_helpers.dart';
import 'package:achievia/data/data_source/reviewer/question_bank_remote_datasource.dart';
import 'package:achievia/data/repositoryImpl/questions/question_bank_repository_impl.dart';
import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/repository/questions/question_bank_repository.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/provider/progress/progress_provider.dart';

final questionBankRepositoryProvider = Provider<QuestionBankRepository>((ref) {
  return QuestionBankRepositoryImpl(QuestionBankRemoteDatasource());
});

/// Clock used for the exam deadline (overridable in tests).
final questionBankClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final questionBankSubjectsProvider = FutureProvider<List<QuestionBankSubject>>((
  ref,
) async {
  final profile = await ref.watch(profileProvider.future);
  final courseId = profile.courseId;
  final repository = ref.read(questionBankRepositoryProvider);
  if (courseId != null) {
    return repository.getSubjectsForCourse(courseId);
  }

  final subjects = await repository.getAllSubjects();
  final availableCourseIds = subjects
      .map((subject) => subject.courseId)
      .toSet();
  if (availableCourseIds.length > 1) {
    throw const QuestionBankCourseMissingException();
  }
  return subjects;
});

final questionBankTopicsProvider =
    FutureProvider.family<List<QuestionBankTopic>, int>((ref, subjectId) {
      return ref.read(questionBankRepositoryProvider).getTopics(subjectId);
    });

final questionBankQuestionsProvider =
    FutureProvider.family<List<QuestionItemEntity>, int>((ref, quizId) {
      return ref
          .read(questionBankRepositoryProvider)
          .getPracticeQuestions(quizId);
    });

/// Persisted summary of one completed exam, loaded by attempt id (so Profile
/// can reuse it). Watching the account id drops any cached summary when the
/// signed-in user changes; autoDispose drops it when nobody is looking.
///
/// Automatic retry is disabled: a missing, legacy or inconsistent summary is a
/// stable answer, and retrying it would keep the screen on a spinner. The
/// screen offers an explicit Retry instead.
final examSummaryProvider = FutureProvider.autoDispose
    .family<ExamAttemptSummary, String>((ref, attemptId) async {
      await ref.watch(activeAccountIdProvider.future);
      return ref.read(questionBankRepositoryProvider).getExamSummary(attemptId);
    }, retry: (_, _) => null);

final recentQuestionBankAttemptsProvider =
    FutureProvider<List<QuestionBankAttempt>>((ref) {
      return ref
          .read(questionBankRepositoryProvider)
          .getRecentAttempts(limit: 5);
    });

/// Profile's source of completed subject exams. The subject_exam filter runs
/// in the query before ordering and limiting, so practice attempts can never
/// push a valid recent exam out of the window. Only 3 are needed because
/// Profile shows at most 3 results in total.
final recentSubjectExamAttemptsProvider =
    FutureProvider<List<QuestionBankAttempt>>((ref) {
      return ref
          .read(questionBankRepositoryProvider)
          .getRecentAttempts(
            limit: examHistoryLimit,
            attemptType: QuestionBankAttempt.subjectExamType,
          );
    });

class QuestionBankSessionState {
  final QuestionBankSelection? selection;
  final List<QuestionItemEntity> questions;
  final int currentIndex;
  final Map<int, int> selectedAnswers;
  final int correctAnswers;
  final bool isSubmitting;
  final Object? saveError;
  final QuestionBankCompletion? completion;

  /// Absolute deadline of a timed subject exam; null for practice.
  final DateTime? endsAt;

  /// Ids of explicitly skipped questions that are still unanswered.
  final Set<int> skippedIds;

  /// True once the first pass is done and skipped questions are revisited.
  final bool inReview;

  /// True once submission started (manual or timeout): no more changes.
  final bool closed;

  /// Idempotency key of this exam session; sent with every save attempt so a
  /// retry returns the same saved attempt instead of creating another.
  final String clientAttemptId;

  const QuestionBankSessionState({
    this.selection,
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedAnswers = const {},
    this.correctAnswers = 0,
    this.isSubmitting = false,
    this.saveError,
    this.completion,
    this.endsAt,
    this.skippedIds = const {},
    this.inReview = false,
    this.closed = false,
    this.clientAttemptId = '',
  });

  /// Score = correct answers only.
  int get score => correctAnswers;

  /// Remaining = all unanswered questions (skipped ones included).
  int get remaining => questions.length - selectedAnswers.length;

  int get skippedCount => skippedIds.length;

  bool isAnswered(int questionId) => selectedAnswers.containsKey(questionId);

  QuestionBankSessionState copyWith({
    QuestionBankSelection? selection,
    List<QuestionItemEntity>? questions,
    int? currentIndex,
    Map<int, int>? selectedAnswers,
    int? correctAnswers,
    bool? isSubmitting,
    Object? saveError,
    bool clearSaveError = false,
    QuestionBankCompletion? completion,
    Set<int>? skippedIds,
    bool? inReview,
    bool? closed,
  }) {
    return QuestionBankSessionState(
      selection: selection ?? this.selection,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      saveError: clearSaveError ? null : saveError ?? this.saveError,
      completion: completion ?? this.completion,
      endsAt: endsAt,
      skippedIds: skippedIds ?? this.skippedIds,
      inReview: inReview ?? this.inReview,
      closed: closed ?? this.closed,
      clientAttemptId: clientAttemptId,
    );
  }
}

final questionBankSessionProvider =
    NotifierProvider.autoDispose<
      QuestionBankSessionNotifier,
      QuestionBankSessionState
    >(QuestionBankSessionNotifier.new);

class QuestionBankSessionNotifier extends Notifier<QuestionBankSessionState> {
  Future<QuestionBankCompletion>? _completionFuture;

  @override
  QuestionBankSessionState build() => const QuestionBankSessionState();

  void start({
    required QuestionBankSelection selection,
    required List<QuestionItemEntity> questions,
    Duration? timeLimit,
  }) {
    _completionFuture = null;
    state = QuestionBankSessionState(
      selection: selection,
      clientAttemptId: newClientAttemptId(),
      questions: List.unmodifiable(questions),
      endsAt: timeLimit == null
          ? null
          : ref.read(questionBankClockProvider)().add(timeLimit),
    );
  }

  void answer(int choiceIndex) {
    if (state.currentIndex < 0 ||
        state.currentIndex >= state.questions.length) {
      return;
    }

    final question = state.questions[state.currentIndex];
    if (state.closed ||
        state.selectedAnswers.containsKey(question.id) ||
        choiceIndex < 0 ||
        choiceIndex >= question.choices.length) {
      return;
    }

    final answers = {...state.selectedAnswers, question.id: choiceIndex};
    final correctAnswers =
        state.correctAnswers +
        (question.choices[choiceIndex].isCorrect ? 1 : 0);
    state = state.copyWith(
      selectedAnswers: Map.unmodifiable(answers),
      correctAnswers: correctAnswers,
      skippedIds: {...state.skippedIds}..remove(question.id),
    );
  }

  bool next() {
    if (state.currentIndex < 0 ||
        state.currentIndex >= state.questions.length) {
      return false;
    }

    final question = state.questions[state.currentIndex];
    if (!state.selectedAnswers.containsKey(question.id) ||
        state.currentIndex >= state.questions.length - 1) {
      return false;
    }

    state = state.copyWith(currentIndex: state.currentIndex + 1);
    return true;
  }

  /// Exam: moves on after the current question was answered. Returns true
  /// when the exam is finished (nothing left unanswered).
  bool advance() {
    if (state.closed) return false;
    if (state.remaining == 0) return true;
    if (!_currentAnswered()) return false;
    return _moveToNext();
  }

  /// Exam: skips the current unanswered question. It stays unanswered and is
  /// counted once in [QuestionBankSessionState.skippedIds].
  void skip() {
    if (state.closed || _currentAnswered()) return;
    if (state.currentIndex < 0 ||
        state.currentIndex >= state.questions.length) {
      return;
    }
    final id = state.questions[state.currentIndex].id;
    state = state.copyWith(skippedIds: {...state.skippedIds, id});
    _moveToNext();
  }

  bool _currentAnswered() {
    if (state.currentIndex < 0 ||
        state.currentIndex >= state.questions.length) {
      return true;
    }
    return state.isAnswered(state.questions[state.currentIndex].id);
  }

  /// First pass runs in order to the last question; afterwards the still
  /// unanswered (skipped) questions are cycled in original order.
  bool _moveToNext() {
    if (state.remaining == 0) return true;
    final last = state.questions.length - 1;
    if (!state.inReview && state.currentIndex < last) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
      return false;
    }
    final unanswered = <int>[
      for (var i = 0; i < state.questions.length; i++)
        if (!state.isAnswered(state.questions[i].id)) i,
    ];
    final after = unanswered.where((i) => i > state.currentIndex);
    final target = state.inReview && after.isNotEmpty
        ? after.first
        : unanswered.first;
    state = state.copyWith(currentIndex: target, inReview: true);
    return false;
  }

  Future<QuestionBankCompletion> complete() {
    final savedCompletion = state.completion;
    if (savedCompletion?.isSaved == true) {
      return Future.value(savedCompletion);
    }

    final pending = _completionFuture;
    if (pending != null) return pending;

    final future = _save();
    _completionFuture = future;
    return future.whenComplete(() => _completionFuture = null);
  }

  Future<QuestionBankCompletion> retrySave() => complete();

  /// Exact record of the finished exam (original order, selected answers,
  /// unanswered items). Null for practice or if a question cannot be
  /// represented honestly; the score is then saved without a summary.
  ExamAttemptSnapshot? _snapshotFor(QuestionBankSelection selection) {
    if (!selection.isSubjectExam) return null;
    try {
      return ExamAttemptSnapshot.fromSession(
        clientAttemptId: state.clientAttemptId,
        questions: state.questions,
        selectedAnswers: state.selectedAnswers,
      );
    } on StateError {
      return null;
    }
  }

  Future<QuestionBankCompletion> _save() async {
    final selection = state.selection;
    if (selection == null || state.questions.isEmpty) {
      throw StateError('A Question Bank session has not been started.');
    }

    state = state.copyWith(
      isSubmitting: true,
      closed: true,
      clearSaveError: true,
    );
    final snapshot = _snapshotFor(selection);
    try {
      final attempt = await ref
          .read(questionBankRepositoryProvider)
          .saveAttempt(
            selection: selection,
            correctAnswers: state.correctAnswers,
            totalQuestions: state.questions.length,
            snapshot: snapshot,
          );
      final completion = QuestionBankCompletion(
        attempt: attempt,
        isSaved: true,
        snapshot: snapshot,
      );
      state = state.copyWith(
        isSubmitting: false,
        completion: completion,
        clearSaveError: true,
      );
      ref.invalidate(recentQuestionBankAttemptsProvider);
      ref.invalidate(recentSubjectExamAttemptsProvider);
      ref.invalidate(progressProvider);
      return completion;
    } catch (error) {
      final attempt = QuestionBankAttempt(
        id: '',
        userId: '',
        subjectId: selection.subject.id,
        topicId: selection.topic?.id,
        subjectTitle: selection.subject.title,
        topicTitle: selection.topic?.title ?? subjectExamTitle,
        attemptType: selection.attemptType,
        correctAnswers: state.correctAnswers,
        totalQuestions: state.questions.length,
        score: questionBankScore(
          correct: state.correctAnswers,
          total: state.questions.length,
        ),
        completedAt: DateTime.now(),
      );
      final completion = QuestionBankCompletion(
        attempt: attempt,
        isSaved: false,
        snapshot: snapshot,
      );
      state = state.copyWith(
        isSubmitting: false,
        saveError: error,
        completion: completion,
      );
      return completion;
    }
  }
}
