import 'dart:math';

import 'package:achievia/core/utils/mock_board_errors.dart';
import 'package:achievia/core/utils/mock_board_loader.dart';
import 'package:achievia/core/utils/questions_helpers.dart';
import 'package:achievia/data/models/quiz/quiz_dto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mycology and Virology each supply "2 questions from any of their topics"
/// (subjects.mock_board_pool_count), next to fixed per-topic counts.
class PoolBoard {
  PoolBoard({int mycologyPool = 2, int virologyPool = 2}) {
    const fixed = {
      1: 'Clinical Chemistry',
      2: 'Bacteriology',
      3: 'Clinical Microscopy',
      4: 'Hematology',
      5: 'Immunology and Serology',
      6: 'Histopath',
    };
    fixed.forEach((id, title) {
      subjects.add(_subject(id, title));
      _topic(
        id,
        id * 10,
        count: id == 2 ? 100 - mycologyPool - virologyPool : 100,
      );
    });
    subjects.add(_subject(7, 'Mycology', pool: mycologyPool));
    for (var t = 0; t < 3; t++) {
      _topic(7, 70 + t, questions: 5);
    }
    subjects.add(_subject(8, 'Virology', pool: virologyPool));
    for (var t = 0; t < 2; t++) {
      _topic(8, 80 + t, questions: 5);
    }
  }

  final subjects = <Map<String, dynamic>>[];
  final quizzesBySubject = <int, List<Map<String, dynamic>>>{};
  final questionsByQuiz = <int, List<Map<String, dynamic>>>{};
  final choicesByQuestion = <int, List<Map<String, dynamic>>>{};

  Map<String, dynamic> _subject(int id, String title, {int? pool}) => {
    'id': id,
    'title': title,
    'created_at': '2026-01-01T00:00:00.000Z',
    if (pool != null) 'mock_board_pool_count': pool,
  };

  void _topic(int subjectId, int quizId, {int? count, int? questions}) {
    quizzesBySubject.putIfAbsent(subjectId, () => []).add({
      'id': quizId,
      'title': 'Topic $quizId',
      'subject_id': subjectId,
      if (count != null) 'configured_question_count': count,
    });
    questionsByQuiz[quizId] = [
      for (var i = 0; i < (questions ?? (count ?? 0) + 5); i++)
        {
          'id': quizId * 1000 + i,
          'quiz_id': quizId,
          'question_text': 'Q ${quizId * 1000 + i}',
        },
    ];
    for (final q in questionsByQuiz[quizId]!) {
      final id = q['id'] as int;
      choicesByQuestion[id] = [
        for (var c = 0; c < 4; c++)
          {
            'id': id * 10 + c,
            'question_id': id,
            'choice_text': 'C$c',
            'is_correct': c == 0,
          },
      ];
    }
  }

  List<QuizDtoItems> build({int seed = 1}) => buildMockBoardQuizItemsFromRows(
    subjects: subjects,
    quizzesBySubject: quizzesBySubject,
    questionsByQuiz: questionsByQuiz,
    choicesByQuestion: choicesByQuestion,
    random: Random(seed),
  );
}

int _quizOf(int questionId) => questionId ~/ 1000;

void main() {
  group('Mock Board topic pools', () {
    test('a pooled subject supplies exactly its count from its topics', () {
      final sections = PoolBoard().build();
      for (final section in sections) {
        expect(section.questions, hasLength(100));
      }
      final micro = sections[1].questions.map((q) => _quizOf(q.id)).toList();
      expect(micro.where((quiz) => quiz >= 70 && quiz < 73), hasLength(2));
      expect(micro.where((quiz) => quiz >= 80 && quiz < 82), hasLength(2));
      expect(micro.where((quiz) => quiz == 20), hasLength(96));
    });

    test('pooled questions come from different topics across boards', () {
      final topics = <int>{};
      for (var seed = 0; seed < 40; seed++) {
        topics.addAll(
          PoolBoard()
              .build(seed: seed)[1]
              .questions
              .map((q) => _quizOf(q.id))
              .where((quiz) => quiz >= 70 && quiz < 73),
        );
      }
      expect(topics, {70, 71, 72});
    });

    test('topics of a pooled subject need no count of their own', () {
      final board = PoolBoard();
      // A stray per-topic count inside the pool is ignored, not added.
      board.quizzesBySubject[7]!.first['configured_question_count'] = 50;
      expect(board.build()[1].questions, hasLength(100));
    });

    test('a pool that breaks the section total is not configured', () {
      final board = PoolBoard();
      board.subjects.last['mock_board_pool_count'] = 3;
      expect(
        () => board.build(),
        throwsA(
          isA<MockBoardException>().having(
            (e) => e.failure,
            'failure',
            MockBoardFailure.notConfigured,
          ),
        ),
      );
    });

    test('a pool without live topics is not configured', () {
      final board = PoolBoard();
      board.quizzesBySubject[8] = [];
      expect(
        () => board.build(),
        throwsA(
          isA<MockBoardException>().having(
            (e) => e.failure,
            'failure',
            MockBoardFailure.notConfigured,
          ),
        ),
      );
    });

    test('a pool too small for its count is "not enough questions"', () {
      final board = PoolBoard();
      for (final quiz in [80, 81]) {
        board.questionsByQuiz[quiz] = board.questionsByQuiz[quiz]!
            .take(quiz == 80 ? 1 : 0)
            .toList();
      }
      expect(
        () => board.build(),
        throwsA(
          isA<MockBoardException>().having(
            (e) => e.failure,
            'failure',
            MockBoardFailure.notEnoughQuestions,
          ),
        ),
      );
    });

    test('the loader fetches candidates from every pooled topic', () async {
      final board = PoolBoard();
      final source = _Source(board);
      final sections = await loadMockBoardQuizItems(
        board.subjects,
        source: source,
        random: Random(3),
      );
      expect(sections[1].questions, hasLength(100));
      for (final quiz in [70, 71, 72, 80, 81]) {
        expect(source.requestedQuizzes, contains(quiz));
      }
    });
  });
}

class _Source implements MockBoardSource {
  _Source(this.board);
  final PoolBoard board;
  final requestedQuizzes = <int>{};

  @override
  Future<List<Map<String, dynamic>>> liveQuizzes(int subjectId) async =>
      board.quizzesBySubject[subjectId] ?? const [];

  @override
  Future<List<int>> liveQuestionIds(int quizId) async => [
    for (final q in board.questionsByQuiz[quizId] ?? const []) q['id'] as int,
  ];

  @override
  Future<List<Map<String, dynamic>>> questions(List<int> ids) async {
    final out = [
      for (final list in board.questionsByQuiz.values)
        for (final q in list)
          if (ids.contains(q['id'])) q,
    ];
    requestedQuizzes.addAll(out.map((q) => q['quiz_id'] as int));
    return out;
  }

  @override
  Future<List<Map<String, dynamic>>> choices(List<int> questionIds) async => [
    for (final id in questionIds) ...?board.choicesByQuestion[id],
  ];
}
