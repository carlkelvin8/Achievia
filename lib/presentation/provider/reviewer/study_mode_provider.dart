import 'dart:async';
import 'dart:math';

import 'package:achievia/core/utils/study_deck.dart';
import 'package:achievia/core/utils/study_progress_store.dart';
import 'package:achievia/data/data_source/reviewer/question_bank_remote_datasource.dart';
import 'package:achievia/data/repositoryImpl/questions/study_deck_repository_impl.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/repository/questions/study_deck_repository.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final studyDeckRepositoryProvider = Provider<StudyDeckRepository>(
  (ref) => StudyDeckRepositoryImpl(QuestionBankRemoteDatasource()),
);

final studyProgressStoreProvider = Provider<StudyProgressStore>(
  (ref) => const SharedPrefsStudyProgressStore(),
);

/// Randomness for Shuffle Questions / Shuffle Choices; overridden in tests.
final studyRandomProvider = Provider<Random>((ref) => Random());

/// Identity of one study deck: a subtopic (quiz) of a subject. The signed-in
/// user is added by the notifier, so a deck is always per user AND subtopic.
typedef StudyModeKey = ({int subjectId, int quizId});

/// Everything the Study Mode screen shows, from one authoritative state.
class StudyModeState {
  final StudyModeKey key;
  final Map<int, QuestionItemEntity> questionsById;
  final List<QuestionItemEntity> questions; // canonical order
  final StudyProgress progress;

  /// Choice id picked for the CURRENT presentation; null until answered. It is
  /// transient on purpose: after a restart the current card is unanswered.
  final int? selectedChoiceId;
  final bool rationaleOpen;

  /// True when the last local save failed. The in-memory deck stays valid.
  final bool persistFailed;

  const StudyModeState({
    required this.key,
    required this.questionsById,
    required this.questions,
    required this.progress,
    this.selectedChoiceId,
    this.rationaleOpen = false,
    this.persistFailed = false,
  });

  int get remaining => progress.remaining;
  int get repeat => progress.repeat;
  int get done => progress.done;
  int get deckSize => progress.deckSize;
  bool get isEmpty => progress.isEmpty;
  bool get isComplete => progress.isComplete;
  bool get answered => selectedChoiceId != null;

  QuestionItemEntity? get current {
    final id = progress.currentId;
    return id == null ? null : questionsById[id];
  }

  List<ChoiceEntity> get currentChoices {
    final q = current;
    return q == null ? const [] : StudyDeck.orderedChoices(q, progress);
  }

  bool get selectedIsCorrect =>
      currentChoices.any((c) => c.id == selectedChoiceId && c.isCorrect);

  StudyModeState copyWith({
    StudyProgress? progress,
    int? selectedChoiceId,
    bool clearAnswer = false,
    bool? rationaleOpen,
    bool? persistFailed,
  }) => StudyModeState(
    key: key,
    questionsById: questionsById,
    questions: questions,
    progress: progress ?? this.progress,
    selectedChoiceId: clearAnswer
        ? null
        : (selectedChoiceId ?? this.selectedChoiceId),
    rationaleOpen: clearAnswer ? false : (rationaleOpen ?? this.rationaleOpen),
    persistFailed: persistFailed ?? this.persistFailed,
  );
}

final studyModeProvider = AsyncNotifierProvider.autoDispose
    .family<StudyModeNotifier, StudyModeState, StudyModeKey>(
      StudyModeNotifier.new,
      // A failed load is shown with an explicit Retry, not retried in a loop.
      retry: (_, _) => null,
    );

/// Owns the deck, current question, answer lock, queue and counters of one
/// user's study session for one subtopic.
///
/// Every action is a synchronous transition: the new state is computed from the
/// current one and published at once, then persisted in write order. That makes
/// double taps and near-simultaneous actions safe (the second one sees the
/// already-updated state) without any timers or locks.
class StudyModeNotifier extends AsyncNotifier<StudyModeState> {
  StudyModeNotifier(this.key);

  final StudyModeKey key;
  String? _userId;
  Future<void> _writes = Future.value();

  @override
  Future<StudyModeState> build() async {
    // Watching the account rebuilds (and so discards) this state when the
    // signed-in user changes or signs out.
    final userId = await ref.watch(activeAccountIdProvider.future);
    if (userId == null) throw StateError('Sign in to study.');
    _userId = userId;
    final random = ref.read(studyRandomProvider);
    final questions = await ref
        .read(studyDeckRepositoryProvider)
        .getStudyQuestions(key.quizId);

    StudyProgress? stored;
    try {
      stored = await ref
          .read(studyProgressStoreProvider)
          .load(userId, key.quizId);
    } catch (error) {
      debugPrint('Study progress could not be read: ${error.runtimeType}');
    }
    final progress = StudyDeck.reconcile(stored, questions, random: random);
    if (questions.isNotEmpty &&
        stored?.toJsonString() != progress.toJsonString()) {
      _persist(progress);
    }
    return StudyModeState(
      key: key,
      questionsById: {for (final q in questions) q.id: q},
      questions: questions,
      progress: progress,
    );
  }

  StudyModeState? get _data => state.value;

  Random get _random => ref.read(studyRandomProvider);

  /// First valid answer wins; anything after it (or for a choice that is not
  /// on the current card) is ignored. Not persisted: it changes no progress.
  void answer(int choiceId) {
    final s = _data;
    if (s == null || s.answered || s.current == null) return;
    if (!s.current!.choices.any((c) => c.id == choiceId)) return;
    state = AsyncData(s.copyWith(selectedChoiceId: choiceId));
  }

  /// Opens or closes the rationale. Touches nothing else.
  void toggleRationale() {
    final s = _data;
    if (s == null || !s.answered) return;
    state = AsyncData(s.copyWith(rationaleOpen: !s.rationaleOpen));
  }

  void studyAgain() {
    final s = _data;
    if (s == null || !s.answered) return;
    _apply(s, StudyDeck.studyAgain(s.progress));
  }

  void alreadyKnow() {
    final s = _data;
    if (s == null || !s.answered) return;
    _apply(s, StudyDeck.alreadyKnow(s.progress));
  }

  /// Rebuilds the whole deck for this subtopic only.
  void resetDeck() {
    final s = _data;
    if (s == null || s.questions.isEmpty) return;
    _apply(s, StudyDeck.reset(s.progress, s.questions, random: _random));
  }

  void setShuffleQuestions(bool value) {
    final s = _data;
    if (s == null || s.progress.shuffleQuestions == value) return;
    final next = StudyDeck.setShuffleQuestions(
      s.progress,
      value,
      s.questions,
      random: _random,
    );
    // The visible card and its answer are untouched.
    state = AsyncData(s.copyWith(progress: next));
    _persist(next);
  }

  void setShuffleChoices(bool value) {
    final s = _data;
    if (s == null || s.progress.shuffleChoices == value) return;
    final next = StudyDeck.setShuffleChoices(
      s.progress,
      value,
      s.questions,
      random: _random,
      keepId: s.answered ? s.progress.currentId : null,
    );
    state = AsyncData(s.copyWith(progress: next));
    _persist(next);
  }

  /// Deck-moving transition: new progress, fresh (unanswered) presentation.
  void _apply(StudyModeState s, StudyProgress next) {
    state = AsyncData(s.copyWith(progress: next, clearAnswer: true));
    _persist(next);
  }

  /// Writes are chained so they land in order and the last state wins; a failed
  /// write flags [StudyModeState.persistFailed] but never corrupts the deck.
  void _persist(StudyProgress progress) {
    final userId = _userId;
    if (userId == null) return;
    final store = ref.read(studyProgressStoreProvider);
    _writes = _writes.then((_) async {
      try {
        await store.save(userId, key.quizId, progress);
        _flagPersist(false);
      } catch (error) {
        debugPrint('Study progress not saved: ${error.runtimeType}');
        _flagPersist(true);
      }
    });
  }

  void _flagPersist(bool failed) {
    if (!ref.mounted) return;
    final s = _data;
    if (s == null || s.persistFailed == failed) return;
    state = AsyncData(s.copyWith(persistFailed: failed));
  }
}
