import 'dart:async';
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/utils/qotd_cache.dart';
import 'package:achievia/core/utils/question_of_the_day_picker.dart';
import 'package:achievia/data/data_source/home/questions_remote_datasource.dart';
import 'package:achievia/data/repositoryImpl/questions/qot_repository_impl.dart';
import 'package:achievia/domain/entities/widgets/question_of_the_day_state.dart';
import 'package:achievia/domain/repository/questions/qotd_repository.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:achievia/presentation/provider/home/daily_motivation_provider.dart';
import 'package:achievia/presentation/provider/task/local_day_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final qotdRepositoryProvider = Provider<QotdRepository>(
  (ref) => QotRepositoryImpl(remoteDatasource: QuestionsRemoteDatasource()),
);

/// On-device cache of today's question; null when storage is unavailable
/// (the card then simply loads from the network as before).
final qotdCacheStoreProvider = Provider<QotdCacheStore?>((ref) {
  try {
    return QotdCacheStore(sl<SharedPreferences>());
  } catch (_) {
    return null;
  }
});

/// Single source of truth for the Question of the Day card.
///
/// Rebuilds only when the UTC+8 calendar day changes (shared with the Daily
/// Motivation cycle) or when the signed-in account changes. Rebuilds and
/// navigation never refetch the question.
final qotdStateProvider =
    AsyncNotifierProvider<QuestionOfDayNotifier, QuestionOfTheDayState>(
      QuestionOfDayNotifier.new,
    );

class QuestionOfDayNotifier extends AsyncNotifier<QuestionOfTheDayState> {
  QotdRepository get _repository => ref.read(qotdRepositoryProvider);

  @override
  Future<QuestionOfTheDayState> build() async {
    ref.watch(motivationDayProvider);
    // Watching the future keeps account switches in sync without rebuilding
    // (and refetching) on the initial loading -> data transition.
    final accountId = await ref.watch(activeAccountIdProvider.future);
    if (accountId == null) {
      throw StateError('Sign in to see today\'s question of the day.');
    }
    final now = ref.read(taskClockProvider)();
    final dayKey = QuestionOfTheDayPicker.dayKey(now);

    // Same account, same day: show the stored question at once and only
    // re-check the saved answer in the background.
    final cache = ref.read(qotdCacheStoreProvider);
    final cached = cache?.read(accountId, dayKey);
    if (cached != null) {
      _refreshAnswerInBackground(accountId, cached, now);
      return QuestionOfTheDayState.loaded(
        dayKey: dayKey,
        subjectTitle: cached.subjectTitle,
        question: cached.question,
        answer: cached.answer,
      );
    }

    // Independent lookups run together to keep the card's load time down.
    final (subjects, withQuestions) = await (
      _repository.getSubjects(),
      _repository.getSubjectIdsWithQuestions(),
    ).wait;
    if (subjects.isEmpty) {
      throw StateError('No subjects are configured yet.');
    }
    final eligibleSubjects = subjects
        .where((subject) => withQuestions.contains(subject.id))
        .toList();
    if (eligibleSubjects.isEmpty) {
      throw StateError('No daily question is available today.');
    }

    // Deterministic subject for the day; a subject whose questions are all
    // malformed hands the day to the next subject in the rotation.
    final start = QuestionOfTheDayPicker.subjectIndex(
      now,
      eligibleSubjects.length,
    );
    QotdSubject? subject;
    int? questionId;
    for (var step = 0; step < eligibleSubjects.length; step++) {
      final candidate =
          eligibleSubjects[(start + step) % eligibleSubjects.length];
      final repository = _repository;
      final picked = repository is PagedQotdRepository
          ? await (repository as PagedQotdRepository).getDailyQuestionId(
              candidate.id,
              now,
            )
          : await QuestionOfTheDayPicker.pickEligibleQuestionId(
              now: now,
              liveIds: await repository.getLiveQuestionIds(candidate.id),
              filterEligible: repository.filterEligibleQuestionIds,
            );
      if (picked != null) {
        subject = candidate;
        questionId = picked;
        break;
      }
    }
    if (subject == null || questionId == null) {
      throw StateError('No daily question is available today.');
    }

    final (question, answer) = await (
      _repository.getQuestion(questionId),
      _repository.getTodaysAnswer(
        questionId: questionId,
        dayStartUtc: QuestionOfTheDayPicker.dayStartUtc(now),
        dayEndUtc: QuestionOfTheDayPicker.dayEndUtc(now),
      ),
    ).wait;
    unawaited(
      cache?.write(
        accountId,
        QotdCacheEntry(
          dayKey: dayKey,
          subjectTitle: subject.title,
          question: question,
          answer: answer,
        ),
      ),
    );
    return QuestionOfTheDayState.loaded(
      dayKey: dayKey,
      subjectTitle: subject.title,
      question: question,
      answer: answer,
    );
  }

  /// Confirms the saved answer of a cached question (it may have been given
  /// on another device) and corrects the card only when it differs.
  void _refreshAnswerInBackground(
    String accountId,
    QotdCacheEntry cached,
    DateTime now,
  ) {
    Future<void>(() async {
      try {
        final answer = await _repository.getTodaysAnswer(
          questionId: cached.question.questionId,
          dayStartUtc: QuestionOfTheDayPicker.dayStartUtc(now),
          dayEndUtc: QuestionOfTheDayPicker.dayEndUtc(now),
        );
        if (!ref.mounted) return;
        final current = state.value;
        if (current == null ||
            current.isSaving ||
            current.dayKey != cached.dayKey ||
            ref.read(activeAccountIdProvider).value != accountId ||
            current.questionId != cached.question.questionId) {
          return;
        }
        final sameAnswer = answer == null
            ? !current.isAnswered
            : current.isAnswered &&
                  current.selectedIndex ==
                      cached.question.choices.indexWhere(
                        (c) => c.id == answer.choiceId,
                      );
        if (sameAnswer) return;
        state = AsyncData(
          QuestionOfTheDayState.loaded(
            dayKey: current.dayKey,
            subjectTitle: current.subjectTitle,
            question: cached.question,
            answer: answer,
          ),
        );
        await ref
            .read(qotdCacheStoreProvider)
            ?.write(
              accountId,
              QotdCacheEntry(
                dayKey: current.dayKey,
                subjectTitle: current.subjectTitle,
                question: cached.question,
                answer: answer,
              ),
            );
      } catch (_) {
        // Offline or transient: the cached card stays usable.
      }
    });
  }

  /// Records the user's answer. The first valid tap is final: while saving and
  /// after answering every option is locked, and a failed save restores the
  /// card to its unanswered state with an inline retry message.
  Future<void> answerOption(int index) async {
    final asyncState = state;
    if (asyncState is! AsyncData) return;
    final data = asyncState.value;
    if (data == null || data.isAnswered || data.isSaving) return;
    if (index < 0 || index >= data.choices.length) return;

    final choice = data.choices[index];
    state = AsyncData(
      data.copyWith(selectedIndex: index, isSaving: true, clearError: true),
    );

    try {
      final accountId = ref.read(activeAccountIdProvider).value;
      if (accountId == null) {
        throw StateError('The signed-in account is no longer available.');
      }
      await _repository.submitAnswer(
        userId: accountId,
        questionId: data.questionId,
        quizId: data.quizId,
        choiceId: choice.id,
        isCorrect: choice.isCorrect,
      );
      if (!ref.mounted) return;
      final cacheStore = ref.read(qotdCacheStoreProvider);
      if (cacheStore != null) {
        await cacheStore.write(
          accountId,
          QotdCacheEntry(
            dayKey: data.dayKey,
            subjectTitle: data.subjectTitle,
            question: QotdDailyQuestion(
              questionId: data.questionId,
              quizId: data.quizId,
              questionText: data.questionText,
              imagePath: data.imagePath,
              rationale: data.rationale,
              choices: data.choices,
            ),
            answer: QotdUserAnswer(
              choiceId: choice.id,
              isCorrect: choice.isCorrect,
              answeredAt: DateTime.now().toUtc(),
            ),
          ),
        );
        if (!ref.mounted) return;
      }
      state = AsyncData(
        data.copyWith(
          selectedIndex: index,
          isAnswered: true,
          isCorrect: choice.isCorrect,
          isSaving: false,
          clearError: true,
        ),
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = AsyncData(
        data.copyWith(
          clearSelection: true,
          isAnswered: false,
          isCorrect: false,
          isSaving: false,
          errorMessage: 'Your answer could not be saved. Please try again.',
        ),
      );
    }
  }
}
