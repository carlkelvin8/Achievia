import 'dart:math';

import 'package:achievia/core/utils/question_bank_helpers.dart';
import 'package:achievia/core/utils/question_eligibility.dart';
import 'package:achievia/core/utils/study_questions_builder.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> question(int id, {String? deletedAt}) => {
  'id': id,
  'quiz_id': 1,
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

/// Four live choices with exactly one correct answer.
List<Map<String, dynamic>> wellFormed(int questionId) => [
  for (var i = 0; i < 4; i++)
    choice(questionId * 10 + i, questionId, correct: i == 0),
];

const deleted = '2026-01-01T00:00:00Z';

void main() {
  group('validQuestionIdsFromChoices', () {
    test('accepts exactly one correct live choice', () {
      expect(validQuestionIdsFromChoices(wellFormed(1)), {1});
    });

    test('a soft-deleted choice is ignored', () {
      final rows = [
        ...wellFormed(1),
        // A deleted second "correct" choice must not make the question invalid.
        choice(99, 1, correct: true, deletedAt: deleted),
      ];
      expect(validQuestionIdsFromChoices(rows), {1});
    });

    test('a deleted correct choice leaves the question with no answer', () {
      final rows = [
        choice(11, 1, correct: true, deletedAt: deleted),
        choice(12, 1),
        choice(13, 1),
      ];
      expect(validQuestionIdsFromChoices(rows), isEmpty);
    });

    test('no correct choice is malformed', () {
      expect(
        validQuestionIdsFromChoices([choice(1, 1), choice(2, 1)]),
        isEmpty,
      );
    });

    test('multiple correct choices are malformed', () {
      expect(
        validQuestionIdsFromChoices([
          choice(1, 1, correct: true),
          choice(2, 1, correct: true),
        ]),
        isEmpty,
      );
    });

    test('minChoices rejects a question with too few live choices', () {
      final rows = [choice(1, 1, correct: true)];
      expect(validQuestionIdsFromChoices(rows), {1});
      expect(validQuestionIdsFromChoices(rows, minChoices: 2), isEmpty);
    });

    test('a duplicated page row is counted once', () {
      final rows = [
        choice(1, 1, correct: true),
        choice(1, 1, correct: true),
        choice(2, 1),
      ];
      expect(validQuestionIdsFromChoices(rows, minChoices: 2), {1});
    });
  });

  group('Question Bank practice/exam builder', () {
    List<int> build(
      List<Map<String, dynamic>> questions,
      List<Map<String, dynamic>> choices,
    ) => buildQuestionBankPracticeQuestions(
      questionRows: questions,
      choiceRows: choices,
      limit: 1000,
    ).map((q) => q.id).toList()..sort();

    test('keeps well-formed questions', () {
      expect(build([question(1)], wellFormed(1)), [1]);
    });

    test('excludes a soft-deleted question', () {
      expect(
        build(
          [question(1, deletedAt: deleted), question(2)],
          [...wellFormed(1), ...wellFormed(2)],
        ),
        [2],
      );
    });

    test('excludes a question whose only correct choice is deleted', () {
      expect(
        build(
          [question(1)],
          [choice(11, 1, correct: true, deletedAt: deleted), choice(12, 1)],
        ),
        isEmpty,
      );
    });

    test('excludes a question with no correct choice', () {
      expect(build([question(1)], [choice(1, 1), choice(2, 1)]), isEmpty);
    });

    test('excludes a question with several correct choices', () {
      expect(
        build(
          [question(1)],
          [choice(1, 1, correct: true), choice(2, 1, correct: true)],
        ),
        isEmpty,
      );
    });

    test('one malformed question does not drop the others', () {
      expect(
        build(
          [question(1), question(2), question(3)],
          [...wellFormed(1), choice(21, 2), ...wellFormed(3)],
        ),
        [1, 3],
      );
    });
  });

  group('Study Mode builder', () {
    List<int> build(
      List<Map<String, dynamic>> questions,
      List<Map<String, dynamic>> choices,
    ) => buildStudyQuestions(
      questionRows: questions,
      choiceRows: choices,
    ).map((q) => q.id).toList();

    test('excludes deleted and malformed questions, keeps the rest', () {
      final ids = build(
        [
          question(1),
          question(2, deletedAt: deleted),
          question(3),
          question(4),
          question(5),
        ],
        [
          ...wellFormed(1),
          ...wellFormed(2),
          choice(31, 3), // no correct
          choice(32, 3),
          choice(41, 4, correct: true), // two correct
          choice(42, 4, correct: true),
          ...wellFormed(5),
        ],
      );
      expect(ids, [1, 5]);
    });

    test('a deleted choice never appears in the deck', () {
      final built = buildStudyQuestions(
        questionRows: [question(1)],
        choiceRows: [
          ...wellFormed(1),
          choice(99, 1, deletedAt: deleted),
        ],
      );
      expect(built.single.choices.map((c) => c.id), isNot(contains(99)));
      expect(built.single.choices, hasLength(4));
    });
  });

  group('Take an Exam selection', () {
    final questions = [for (var id = 1; id <= 130; id++) question(id)];
    // 5 deleted questions, plus 3 malformed ones among the live questions.
    final deletedIds = {1, 2, 3, 4, 5};
    final malformed = {6, 7, 8};

    List<Map<String, dynamic>> questionRows() => [
      for (final q in questions)
        deletedIds.contains(q['id'])
            ? question(q['id'] as int, deletedAt: deleted)
            : q,
    ];

    List<Map<String, dynamic>> choiceRows() => [
      for (var id = 1; id <= 130; id++)
        if (id == 6) ...[
          choice(61, 6),
          choice(62, 6),
        ] // no correct
        else if (id == 7) ...[
          choice(71, 7, correct: true),
          choice(72, 7, correct: true),
        ] else if (id == 8) ...[
          choice(81, 8, correct: true, deletedAt: deleted),
          choice(82, 8),
        ] else
          ...wellFormed(id),
    ];

    Future<List<int>> draw({int count = 100, int pool = 130}) async {
      final picked = await assembleExamQuestions(
        candidateIds: [for (var id = 1; id <= pool; id++) id],
        count: count,
        random: Random(7),
        loadUsable: (ids) async => buildQuestionBankPracticeQuestions(
          questionRows: [
            for (final row in questionRows())
              if (ids.contains(row['id'])) row,
          ],
          choiceRows: [
            for (final row in choiceRows())
              if (ids.contains(row['question_id'])) row,
          ],
          limit: ids.length,
        ),
      );
      return picked.map((q) => q.id).toList();
    }

    test(
      'draws 100 unique questions and never a deleted or malformed one',
      () async {
        final ids = await draw();
        expect(ids, hasLength(100));
        expect(ids.toSet(), hasLength(100));
        expect(ids.toSet().intersection(deletedIds), isEmpty);
        expect(ids.toSet().intersection(malformed), isEmpty);
      },
    );

    test('fewer than 100 eligible questions yields a short list', () async {
      // Pool of 100 holds 5 deleted + 3 malformed, leaving 92 eligible.
      final ids = await draw(pool: 100);
      expect(ids, hasLength(92));
      expect(ids.length, lessThan(subjectExamQuestionCount));
    });
  });
}
