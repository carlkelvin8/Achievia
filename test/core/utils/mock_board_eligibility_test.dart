import 'dart:io';
import 'dart:math';

import 'package:achievia/core/utils/mock_board_errors.dart';
import 'package:achievia/core/utils/mock_board_loader.dart';
import 'package:achievia/core/utils/questions_helpers.dart';
import 'package:achievia/data/models/quiz/quiz_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const deleted = '2026-01-01T00:00:00Z';

/// Subject titles that match the six Mock Board sections.
const sectionTitles = {
  1: 'Clinical Chemistry',
  2: 'Bacteriology',
  3: 'Clinical Microscopy',
  4: 'Hematology',
  5: 'Immunology and Serology',
  6: 'Histopath',
};

Map<String, dynamic> subject(int id, {String? deletedAt, String? title}) => {
  'id': id,
  'title': title ?? sectionTitles[id],
  'description': '',
  'created_at': '2026-01-01T00:00:00.000Z',
  'deleted_at': deletedAt,
};

Map<String, dynamic> quiz(
  int id,
  int subjectId, {
  int? count = 100,
  String? deletedAt,
}) => {
  'id': id,
  'title': 'Topic $id',
  'subject_id': subjectId,
  'created_at': '2026-01-01T00:00:00.000Z',
  'deleted_at': deletedAt,
  if (count != null) 'configured_question_count': count,
};

Map<String, dynamic> question(int id, int quizId, {String? deletedAt}) => {
  'id': id,
  'quiz_id': quizId,
  'question_text': 'Question $id',
  'deleted_at': deletedAt,
};

Map<String, dynamic> choice(
  int id,
  int questionId, {
  bool correct = false,
  String? deletedAt,
}) => {
  'id': id,
  'question_id': questionId,
  'choice_text': 'Choice $id',
  'is_correct': correct,
  'deleted_at': deletedAt,
};

List<Map<String, dynamic>> validChoices(int questionId) => [
  for (var i = 0; i < 4; i++)
    choice(questionId * 10 + i, questionId, correct: i == 0),
];

/// One subject, one topic and [pool] valid questions per section.
class Board {
  Board({int pool = 105}) {
    for (final sectionId in sectionTitles.keys) {
      subjects.add(subject(sectionId));
      quizzesBySubject[sectionId] = [quiz(sectionId * 10, sectionId)];
      questionsByQuiz[sectionId * 10] = [
        for (var i = 0; i < pool; i++)
          question(sectionId * 10000 + i, sectionId * 10),
      ];
      for (final q in questionsByQuiz[sectionId * 10]!) {
        choicesByQuestion[q['id'] as int] = validChoices(q['id'] as int);
      }
    }
  }

  final subjects = <Map<String, dynamic>>[];
  final quizzesBySubject = <int, List<Map<String, dynamic>>>{};
  final questionsByQuiz = <int, List<Map<String, dynamic>>>{};
  final choicesByQuestion = <int, List<Map<String, dynamic>>>{};

  List<Map<String, dynamic>> questionsOf(int sectionId) =>
      questionsByQuiz[sectionId * 10]!;

  List<QuizDtoItems> build({int seed = 1}) => buildMockBoardQuizItemsFromRows(
    subjects: subjects,
    quizzesBySubject: quizzesBySubject,
    questionsByQuiz: questionsByQuiz,
    choicesByQuestion: choicesByQuestion,
    random: Random(seed),
  );
}

MockBoardFailure failureOf(Object Function() run) {
  try {
    run();
  } on MockBoardException catch (e) {
    return e.failure;
  }
  fail('expected a MockBoardException');
}

void main() {
  group('Mock Board eligibility', () {
    test('valid data builds six sections of 100 unique questions', () {
      final sections = Board().build();
      expect(sections, hasLength(6));
      for (final section in sections) {
        expect(section.questions, hasLength(100));
      }
      final ids = sections.expand((s) => s.questions).map((q) => q.id);
      expect(ids.toSet(), hasLength(600));
    });

    test(
      'every question keeps exactly one correct, correctly mapped choice',
      () {
        final sections = Board().build();
        for (final q in sections.expand((s) => s.questions)) {
          final correct = q.choices.where((c) => c.isCorrect).toList();
          expect(correct, hasLength(1));
          // In the fixture the first choice (id = question * 10) is the answer.
          expect(correct.single.id, q.id * 10);
          expect(q.choices, hasLength(4));
        }
      },
    );

    test('a soft-deleted subject is ignored', () {
      final board = Board();
      board.subjects.add(subject(99, deletedAt: deleted, title: 'Hematology'));
      board.quizzesBySubject[99] = [quiz(990, 99)];
      board.questionsByQuiz[990] = [question(990001, 990)];
      board.choicesByQuestion[990001] = validChoices(990001);

      final ids = board.build().expand((s) => s.questions).map((q) => q.id);
      expect(ids, isNot(contains(990001)));
    });

    test('a section whose only subject is deleted is not configured', () {
      final board = Board();
      board.subjects[0] = subject(1, deletedAt: deleted);
      expect(failureOf(() => board.build()), MockBoardFailure.notConfigured);
    });

    test('a soft-deleted subtopic is ignored (it would break the total)', () {
      final board = Board();
      board.quizzesBySubject[1]!.add(quiz(11, 1, deletedAt: deleted));
      board.questionsByQuiz[11] = [question(110001, 11)];
      board.choicesByQuestion[110001] = validChoices(110001);

      final sections = board.build();
      expect(sections.first.questions, hasLength(100));
      expect(
        sections.expand((s) => s.questions).map((q) => q.id),
        isNot(contains(110001)),
      );
    });

    test('soft-deleted questions are never selected', () {
      final board = Board(pool: 100);
      final doomed = board.questionsOf(1).take(5).map((q) => q['id']).toList();
      board.questionsByQuiz[10] = [
        for (final q in board.questionsOf(1))
          doomed.contains(q['id'])
              ? question(q['id'] as int, 10, deletedAt: deleted)
              : q,
        // Replacements so the pool still has 100 live questions.
        for (var i = 0; i < 5; i++) question(10 * 100000 + i, 10),
      ];
      for (var i = 0; i < 5; i++) {
        board.choicesByQuestion[10 * 100000 + i] = validChoices(
          10 * 100000 + i,
        );
      }

      final ids = board.build().first.questions.map((q) => q.id).toSet();
      expect(ids, hasLength(100));
      expect(ids.intersection(doomed.cast<int>().toSet()), isEmpty);
    });

    test('soft-deleted choices are removed from the output', () {
      final board = Board();
      final first = board.questionsOf(1).first['id'] as int;
      board.choicesByQuestion[first] = [
        ...validChoices(first),
        choice(777, first, deletedAt: deleted),
      ];
      // Force this question in by shrinking the pool to exactly 100.
      board.questionsByQuiz[10] = board.questionsOf(1).take(100).toList();

      final out = board.build().first.questions.firstWhere(
        (q) => q.id == first,
      );
      expect(out.choices.map((c) => c.id), isNot(contains(777)));
      expect(out.choices, hasLength(4));
    });

    test('a question whose only correct choice is deleted is excluded', () {
      final board = Board(pool: 100);
      final broken = board.questionsOf(1).first['id'] as int;
      board.choicesByQuestion[broken] = [
        choice(broken * 10, broken, correct: true, deletedAt: deleted),
        choice(broken * 10 + 1, broken),
        choice(broken * 10 + 2, broken),
      ];
      // 99 usable questions remain: not enough for a 100-question topic.
      expect(
        failureOf(() => board.build()),
        MockBoardFailure.notEnoughQuestions,
      );
    });

    test(
      'questions with no correct or several correct answers are excluded',
      () {
        final board = Board(pool: 105);
        final ids = board.questionsOf(1).map((q) => q['id'] as int).toList();
        board.choicesByQuestion[ids[0]] = [
          choice(1, ids[0]),
          choice(2, ids[0]),
        ]; // none correct
        board.choicesByQuestion[ids[1]] = [
          choice(3, ids[1], correct: true),
          choice(4, ids[1], correct: true),
        ]; // two correct
        board.choicesByQuestion[ids[2]] = const []; // no choices

        final picked = board.build().first.questions.map((q) => q.id).toSet();
        expect(picked, hasLength(100));
        expect(picked.intersection({ids[0], ids[1], ids[2]}), isEmpty);
      },
    );

    test('too few eligible questions is a clear, typed failure', () {
      final board = Board(pool: 99);
      expect(
        failureOf(() => board.build()),
        MockBoardFailure.notEnoughQuestions,
      );
    });

    test('a question listed under two subtopics is used only once', () {
      final board = Board();
      // Split section 1 into two topics of 50 that share half their rows.
      board.quizzesBySubject[1] = [
        quiz(10, 1, count: 50),
        quiz(11, 1, count: 50),
      ];
      final shared = [
        for (var i = 0; i < 60; i++) question(10 * 10000 + i, 10),
      ];
      board.questionsByQuiz[10] = shared;
      board.questionsByQuiz[11] = [
        ...shared.take(30).map((q) => question(q['id'] as int, 11)),
        for (var i = 0; i < 60; i++) question(11 * 10000 + i, 11),
      ];
      for (final q in [
        ...board.questionsByQuiz[10]!,
        ...board.questionsByQuiz[11]!,
      ]) {
        board.choicesByQuestion[q['id'] as int] = validChoices(q['id'] as int);
      }

      final ids = board.build().first.questions.map((q) => q.id).toList();
      expect(ids, hasLength(100));
      expect(ids.toSet(), hasLength(100));
    });

    test('a subtopic without a configured count is "not configured"', () {
      final board = Board();
      board.quizzesBySubject[1] = [quiz(10, 1, count: null)];
      expect(failureOf(() => board.build()), MockBoardFailure.notConfigured);
    });
  });

  group('loadMockBoardQuizItems', () {
    test('no subjects at all fails cleanly instead of crashing', () async {
      await expectLater(
        loadMockBoardQuizItems(const [], source: FakeSource(Board())),
        throwsA(
          isA<MockBoardException>().having(
            (e) => e.failure,
            'failure',
            MockBoardFailure.notConfigured,
          ),
        ),
      );
    });

    test(
      'production shape (no count column) is reported as not configured',
      () async {
        final board = Board();
        for (final id in sectionTitles.keys) {
          board.quizzesBySubject[id] = [quiz(id * 10, id, count: null)];
        }
        await expectLater(
          loadMockBoardQuizItems(board.subjects, source: FakeSource(board)),
          throwsA(
            isA<MockBoardException>().having(
              (e) => e.failure,
              'failure',
              MockBoardFailure.notConfigured,
            ),
          ),
        );
      },
    );

    test('downloads only what it needs, not the whole bank', () async {
      final board = Board(pool: 2000);
      final source = FakeSource(board);
      final sections = await loadMockBoardQuizItems(
        board.subjects,
        source: source,
        random: Random(3),
      );

      expect(sections.expand((s) => s.questions), hasLength(600));
      // 6 topics x (100 needed + 20 spare) instead of 12,000 questions.
      expect(source.questionsRequested, lessThanOrEqualTo(6 * 120));
      expect(source.maxChunk, lessThanOrEqualTo(120));
    });

    test('tops up when the first batch contains malformed questions', () async {
      final board = Board(pool: 400);
      // Break three quarters of section 1 so the first batches fall short.
      for (final q in board.questionsOf(1).take(300)) {
        board.choicesByQuestion[q['id'] as int] = [choice(1, q['id'] as int)];
      }
      final sections = await loadMockBoardQuizItems(
        board.subjects,
        source: FakeSource(board),
        random: Random(5),
      );

      final first = sections.first.questions;
      expect(first, hasLength(100));
      for (final q in first) {
        expect(q.choices.where((c) => c.isCorrect), hasLength(1));
      }
    });

    test('not enough eligible questions in the whole bank is typed', () async {
      final board = Board(pool: 100);
      for (final q in board.questionsOf(2).take(10)) {
        board.choicesByQuestion[q['id'] as int] = const [];
      }
      await expectLater(
        loadMockBoardQuizItems(board.subjects, source: FakeSource(board)),
        throwsA(
          isA<MockBoardException>().having(
            (e) => e.failure,
            'failure',
            MockBoardFailure.notEnoughQuestions,
          ),
        ),
      );
    });
  });

  group('error classification and safe messages', () {
    test('known causes map to their failure', () {
      expect(
        classifyMockBoardError(const SocketException('Failed host lookup')),
        MockBoardFailure.network,
      );
      expect(
        classifyMockBoardError(
          const PostgrestException(message: 'permission denied', code: '42501'),
        ),
        MockBoardFailure.permission,
      );
      expect(
        classifyMockBoardError(StateError('boom')),
        MockBoardFailure.internal,
      );
      expect(
        classifyMockBoardError(
          MockBoardException(MockBoardFailure.notConfigured, 'x'),
        ),
        MockBoardFailure.notConfigured,
      );
    });

    test('user messages never leak internals', () {
      for (final failure in MockBoardFailure.values) {
        final message = mockBoardUserMessage(failure).toLowerCase();
        for (final secret in [
          'supabase',
          'postgrest',
          'exception',
          'sql',
          'http',
          'quiz',
          'configured_question_count',
        ]) {
          expect(message, isNot(contains(secret)), reason: failure.name);
        }
      }
      expect(
        mockBoardUserMessage(MockBoardFailure.notConfigured),
        isNot(contains('try again later')),
      );
    });
  });
}

/// Serves a [Board] like the live API: live rows only, and it records how much
/// was requested.
class FakeSource implements MockBoardSource {
  FakeSource(this.board);
  final Board board;
  int questionsRequested = 0;
  int maxChunk = 0;

  bool _live(Map<String, dynamic> row) => row['deleted_at'] == null;

  @override
  Future<List<Map<String, dynamic>>> liveQuizzes(int subjectId) async => [
    for (final q in board.quizzesBySubject[subjectId] ?? const [])
      if (_live(q)) q,
  ];

  @override
  Future<List<int>> liveQuestionIds(int quizId) async => [
    for (final q in board.questionsByQuiz[quizId] ?? const [])
      if (_live(q)) q['id'] as int,
  ];

  @override
  Future<List<Map<String, dynamic>>> questions(List<int> ids) async {
    questionsRequested += ids.length;
    maxChunk = max(maxChunk, ids.length);
    return [
      for (final list in board.questionsByQuiz.values)
        for (final q in list)
          if (ids.contains(q['id']) && _live(q)) q,
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> choices(List<int> questionIds) async => [
    for (final id in questionIds)
      for (final c in board.choicesByQuestion[id] ?? const [])
        if (_live(c)) c,
  ];
}
