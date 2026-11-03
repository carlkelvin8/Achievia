import 'package:achievia/core/utils/mock_board_progress.dart';
import 'package:achievia/data/data_source/home/mock_board_progress_remote.dart';
import 'package:achievia/core/utils/questions_helpers.dart' show recordAnswer;
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// On the device, and on the server when Supabase is available.
final mockBoardProgressStoreProvider = Provider<MockBoardProgressStore>((ref) {
  const local = SharedPrefsMockBoardProgressStore();
  try {
    Supabase.instance.client;
  } catch (_) {
    return local;
  }
  final remote = SupabaseMockBoardProgressStore();
  return SyncedMockBoardProgressStore(
    local: local,
    remote: remote,
    rebuild: remote.rebuild,
  );
});

/// The signed-in user's id, read at call time (never cached across accounts).
final mockBoardUserIdProvider = Provider<String? Function()>((ref) {
  return () {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  };
});

/// The unfinished exam that is loaded and can be continued, or null. While it
/// is set the intro page shows CONTINUE EXAM, and the exam screen opens on its
/// subject and question.
final pendingMockBoardProvider = StateProvider<MockBoardProgress?>(
  (ref) => null,
);

/// Whether the exam currently started or continued is a Pre Board.
final activeMockBoardIsPreBoardProvider = StateProvider<bool>((ref) => false);

final mockBoardResumeProvider = Provider<MockBoardResumeController>(
  MockBoardResumeController.new,
);

/// Keeps an unfinished Mock Boards / Pre Boards exam on the device and brings
/// it back exactly where the student left it.
class MockBoardResumeController {
  MockBoardResumeController(this.ref);

  final Ref ref;

  MockBoardProgressStore get _store => ref.read(mockBoardProgressStoreProvider);
  String? get _userId => ref.read(mockBoardUserIdProvider)();

  /// Loads the student's pending exam of this kind and makes it the board in
  /// progress again, with every answer it had. Returns false when there is
  /// none (a new board must then be generated).
  Future<bool> tryRestore({required bool isPreBoard}) async {
    final userId = _userId;
    if (userId == null) return false;
    final PendingMockBoard? pending;
    try {
      pending = await _store.load(userId, isPreBoard);
    } catch (error) {
      debugPrint('Pending Mock Board could not be read: $error');
      return false;
    }
    if (pending == null) return false;

    final useCase = ref.read(getQuestions);
    try {
      useCase.restoreMockBoardSession(pending.session);
    } catch (error) {
      // A board that can no longer be read is dropped, not half-restored.
      debugPrint('Pending Mock Board is unreadable: $error');
      await _store.clear(userId, isPreBoard);
      return false;
    }
    ref.invalidate(getGeneratedQuestions);
    final board = await ref.read(getGeneratedQuestions.future);
    _restoreAnswers(board, pending.progress.selectedAnswers);
    ref.read(examMarkedQuestionsProvider.notifier).state = Set.of(
      pending.progress.markedQuestions,
    );
    ref.read(activeMockBoardIsPreBoardProvider.notifier).state = isPreBoard;
    ref.read(pendingMockBoardProvider.notifier).state = pending.progress;
    return true;
  }

  /// Rebuilds every answer: the review map, the answered badges and the
  /// selections that are submitted for grading.
  void _restoreAnswers(List<QuizItemEntity> board, Map<String, int> answers) {
    final kept = <String, int>{};
    final answered = ref.read(answeredQuestionsProvider.notifier);
    answered.resetState();
    for (final batch in board) {
      for (final question in batch.questions) {
        final key = '${batch.id}:${question.id}';
        final index = answers[key];
        if (index == null || index < 0 || index >= question.choices.length) {
          continue;
        }
        kept[key] = index;
        answered.isAnswered(question.id);
        recordAnswer(
          batch.title,
          question.choices[index].isCorrect,
          questionId: question.id,
          choiceId: question.choices[index].id,
        );
      }
    }
    ref.read(examSelectedAnswersProvider.notifier).state = kept;
  }

  /// Called when a new exam starts: keeps the freshly generated board so the
  /// exam can be continued later.
  Future<void> beginExam({required bool isPreBoard}) async {
    ref.read(activeMockBoardIsPreBoardProvider.notifier).state = isPreBoard;
    ref.read(pendingMockBoardProvider.notifier).state = null;
    final userId = _userId;
    final session = ref.read(getQuestions).exportMockBoardSession();
    if (userId == null || session == null) return;
    try {
      await _store.saveSession(userId, isPreBoard, session);
      await _store.saveProgress(
        userId,
        _snapshot(isPreBoard, subjectIndex: 0, questionIndex: 0),
        flush: true,
      );
    } catch (error) {
      debugPrint('Mock Board could not be kept for later: $error');
    }
  }

  /// Saves where the student is now. With [markPending] the intro page will
  /// offer CONTINUE EXAM (used when the student leaves the exam).
  Future<void> saveProgress({
    required int subjectIndex,
    required int questionIndex,
    bool markPending = false,
  }) async {
    final isPreBoard = ref.read(activeMockBoardIsPreBoardProvider);
    final progress = _snapshot(
      isPreBoard,
      subjectIndex: subjectIndex,
      questionIndex: questionIndex,
    );
    if (markPending) {
      ref.read(pendingMockBoardProvider.notifier).state = progress;
    }
    final userId = _userId;
    if (userId == null) return;
    try {
      await _store.saveProgress(userId, progress, flush: markPending);
    } catch (error) {
      debugPrint('Mock Board progress could not be saved: $error');
    }
  }

  /// The exam was submitted: nothing is pending any more.
  Future<void> finish() async {
    final isPreBoard = ref.read(activeMockBoardIsPreBoardProvider);
    ref.read(pendingMockBoardProvider.notifier).state = null;
    final userId = _userId;
    if (userId == null) return;
    try {
      await _store.clear(userId, isPreBoard);
    } catch (error) {
      debugPrint('Finished Mock Board could not be cleared: $error');
    }
  }

  /// A new board replaces any unfinished exam of this kind.
  Future<void> discard({required bool isPreBoard}) async {
    final pending = ref.read(pendingMockBoardProvider);
    if (pending != null && pending.isPreBoard == isPreBoard) {
      ref.read(pendingMockBoardProvider.notifier).state = null;
    }
    final userId = _userId;
    if (userId == null) return;
    try {
      await _store.clear(userId, isPreBoard);
    } catch (_) {}
  }

  MockBoardProgress _snapshot(
    bool isPreBoard, {
    required int subjectIndex,
    required int questionIndex,
  }) {
    return MockBoardProgress(
      isPreBoard: isPreBoard,
      selectedAnswers: Map.of(ref.read(examSelectedAnswersProvider)),
      markedQuestions: Set.of(ref.read(examMarkedQuestionsProvider)),
      subjectIndex: subjectIndex,
      questionIndex: questionIndex,
      remaining: ref.read(timerProvider).remaining,
      savedAt: DateTime.now(),
    );
  }
}
