import 'package:achievia/core/utils/mock_board_progress.dart';
import 'package:achievia/core/utils/questions_helpers.dart';
import 'package:achievia/data/models/quiz/quiz_dto.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/use_cases/questions/questions_use_case.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/provider/questions/mock_board_resume.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements MockBoardProgressStore {
  final sessions = <String, MockBoardSession>{};
  final progress = <String, MockBoardProgress>{};

  String _key(String user, bool pre) => '$user-$pre';

  @override
  Future<void> saveSession(String u, bool pre, MockBoardSession s) async =>
      sessions[_key(u, pre)] = s;

  @override
  Future<void> saveProgress(
    String u,
    MockBoardProgress p, {
    bool flush = false,
  }) async => progress[_key(u, p.isPreBoard)] = p;

  @override
  Future<PendingMockBoard?> load(String u, bool pre) async {
    final s = sessions[_key(u, pre)];
    final p = progress[_key(u, pre)];
    if (s == null || p == null) return null;
    return PendingMockBoard(session: s, progress: p);
  }

  @override
  Future<void> clear(String u, bool pre) async {
    sessions.remove(_key(u, pre));
    progress.remove(_key(u, pre));
  }
}

/// Holds one board in memory like the real data source.
class _FakeUseCase implements QuestionsUseCase {
  List<QuizDtoItems> board;
  String attemptId;
  _FakeUseCase(this.board, this.attemptId);

  @override
  MockBoardSession? exportMockBoardSession() => MockBoardSession(
    board: [for (final s in board) s.toJson()],
    clientAttemptId: attemptId,
  );

  @override
  void restoreMockBoardSession(MockBoardSession session) {
    resetMockBoardAnswers();
    board = session.board.map(QuizDtoItems.fromJson).toList();
    attemptId = session.clientAttemptId;
  }

  @override
  Future<List<QuizItemEntity>> getGeneratedQuestions() async =>
      board.map((s) => s.toEntity()).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

QuizDtoItems _section(int id, String title, List<int> questionIds) =>
    QuizDtoItems(
      id: id,
      title: title,
      description: '',
      createdAt: '',
      subjectId: id,
      questions: [
        for (final q in questionIds)
          QuestionsItemsDto(
            id: q,
            questionText: 'Q$q with <em>italics</em>',
            imagePath: q == 11 ? 'questions/q11.png' : '',
            rationale: q == 11 ? '<p>Because.</p>' : '',
            choices: [
              for (var c = 0; c < 4; c++)
                ChoicesDto(
                  id: q * 10 + c,
                  choiceText: 'C$c',
                  isCorrect: c == 1,
                  questionId: q,
                ),
            ],
          ),
      ],
    );

void main() {
  late _MemoryStore store;
  var userId = 'user-a';

  ProviderContainer containerFor(_FakeUseCase useCase) {
    final container = ProviderContainer(
      overrides: [
        getQuestions.overrideWithValue(useCase),
        mockBoardProgressStoreProvider.overrideWithValue(store),
        mockBoardUserIdProvider.overrideWithValue(() => userId),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    store = _MemoryStore();
    userId = 'user-a';
    resetMockBoardAnswers();
  });

  test('board JSON round-trips without losing text, image or answers', () {
    final section = _section(1, 'Clinical Chemistry', [10, 11]);
    final back = QuizDtoItems.fromJson(section.toJson());
    expect(back.title, 'Clinical Chemistry');
    expect(back.questions[1].imagePath, 'questions/q11.png');
    expect(back.questions[1].rationale, '<p>Because.</p>');
    expect(back.toEntity().questions[1].rationale, '<p>Because.</p>');
    expect(back.questions[0].questionText, 'Q10 with <em>italics</em>');
    expect(back.questions[0].choices[1].isCorrect, isTrue);
    expect(back.questions[0].choices[1].questionId, 10);
  });

  test('leaving keeps answers, position and time; continuing restores '
      'them exactly', () async {
    final board = [
      _section(1, 'Clinical Chemistry', [10, 11]),
      _section(2, 'Hematology', [20, 21]),
    ];
    final first = containerFor(_FakeUseCase(board, 'attempt-1'));
    final resume = first.read(mockBoardResumeProvider);
    await resume.beginExam(isPreBoard: false);

    // Answer two questions, then leave on subject 2, question 2 at 41:30.
    first.read(examSelectedAnswersProvider.notifier).state = {
      '1:10': 1,
      '2:20': 3,
    };
    first
        .read(timerProvider.notifier)
        .restore(const Duration(minutes: 41, seconds: 30));
    await resume.saveProgress(
      subjectIndex: 1,
      questionIndex: 1,
      markPending: true,
    );
    expect(first.read(pendingMockBoardProvider), isNotNull);

    // App restarted (or signed out and back in): a fresh container.
    resetMockBoardAnswers();
    final fresh = _FakeUseCase(const [], 'other');
    final second = containerFor(fresh);
    expect(
      await second.read(mockBoardResumeProvider).tryRestore(isPreBoard: false),
      isTrue,
    );

    expect(fresh.attemptId, 'attempt-1', reason: 'same attempt, no restart');
    expect(fresh.board.map((s) => s.title), [
      'Clinical Chemistry',
      'Hematology',
    ]);
    expect(second.read(examSelectedAnswersProvider), {'1:10': 1, '2:20': 3});
    expect(second.read(answeredQuestionsProvider), unorderedEquals([10, 20]));
    expect(mockBoardSelections, {10: 101, 20: 203});
    final pending = second.read(pendingMockBoardProvider)!;
    expect(pending.subjectIndex, 1);
    expect(pending.questionIndex, 1);
    expect(pending.remaining, const Duration(minutes: 41, seconds: 30));
    // The exam screen opens on the saved subject and question.
    expect(second.read(changeIndexProvider), 1);
    expect(second.read(changeIndexProviderOuter), 1);
  });

  test('submitting clears it: START EXAM is offered again', () async {
    final container = containerFor(
      _FakeUseCase([
        _section(1, 'Hematology', [20]),
      ], 'attempt-2'),
    );
    final resume = container.read(mockBoardResumeProvider);
    await resume.beginExam(isPreBoard: false);
    await resume.saveProgress(
      subjectIndex: 0,
      questionIndex: 0,
      markPending: true,
    );
    await resume.finish();

    expect(container.read(pendingMockBoardProvider), isNull);
    expect(await resume.tryRestore(isPreBoard: false), isFalse);
  });

  test('a pending exam belongs to its own account and kind', () async {
    final container = containerFor(
      _FakeUseCase([
        _section(1, 'Hematology', [20]),
      ], 'attempt-3'),
    );
    final resume = container.read(mockBoardResumeProvider);
    await resume.beginExam(isPreBoard: false);

    expect(await resume.tryRestore(isPreBoard: true), isFalse);
    userId = 'user-b';
    expect(await resume.tryRestore(isPreBoard: false), isFalse);
    userId = 'user-a';
    expect(await resume.tryRestore(isPreBoard: false), isTrue);
  });

  test('a clock saved at zero still runs out instead of sticking', () {
    final container = containerFor(_FakeUseCase(const [], 'x'));
    container.read(timerProvider.notifier).restore(Duration.zero);
    expect(container.read(timerProvider).remaining, const Duration(seconds: 1));
  });
}
