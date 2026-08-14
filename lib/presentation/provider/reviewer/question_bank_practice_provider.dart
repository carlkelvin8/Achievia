import 'package:achievia/core/utils/question_bank_helpers.dart';
import 'package:achievia/data/data_source/reviewer/question_bank_remote_datasource.dart';
import 'package:achievia/data/repositoryImpl/questions/question_bank_repository_impl.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/repository/questions/question_bank_repository.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final questionBankRepositoryProvider = Provider<QuestionBankRepository>((ref) {
  return QuestionBankRepositoryImpl(QuestionBankRemoteDatasource());
});

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

final recentQuestionBankAttemptsProvider =
    FutureProvider<List<QuestionBankAttempt>>((ref) {
      return ref
          .read(questionBankRepositoryProvider)
          .getRecentAttempts(limit: 5);
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

  const QuestionBankSessionState({
    this.selection,
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedAnswers = const {},
    this.correctAnswers = 0,
    this.isSubmitting = false,
    this.saveError,
    this.completion,
  });

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
  }) {
    _completionFuture = null;
    state = QuestionBankSessionState(
      selection: selection,
      questions: List.unmodifiable(questions),
    );
  }

  void answer(int choiceIndex) {
    if (state.currentIndex < 0 ||
        state.currentIndex >= state.questions.length) {
      return;
    }

    final question = state.questions[state.currentIndex];
    if (state.selectedAnswers.containsKey(question.id) ||
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

  Future<QuestionBankCompletion> _save() async {
    final selection = state.selection;
    if (selection == null || state.questions.isEmpty) {
      throw StateError('A Question Bank session has not been started.');
    }

    state = state.copyWith(isSubmitting: true, clearSaveError: true);
    try {
      final attempt = await ref
          .read(questionBankRepositoryProvider)
          .saveAttempt(
            selection: selection,
            correctAnswers: state.correctAnswers,
            totalQuestions: state.questions.length,
          );
      final completion = QuestionBankCompletion(
        attempt: attempt,
        isSaved: true,
      );
      state = state.copyWith(
        isSubmitting: false,
        completion: completion,
        clearSaveError: true,
      );
      ref.invalidate(recentQuestionBankAttemptsProvider);
      return completion;
    } catch (error) {
      final attempt = QuestionBankAttempt(
        id: '',
        userId: '',
        subjectId: selection.subject.id,
        topicId: selection.topic.id,
        subjectTitle: selection.subject.title,
        topicTitle: selection.topic.title,
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
