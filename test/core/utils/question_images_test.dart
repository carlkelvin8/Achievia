import 'dart:math';

import 'package:achievia/core/utils/module_file_access.dart';
import 'package:achievia/core/utils/question_bank_helpers.dart';
import 'package:achievia/core/utils/study_questions_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('study and randomized practice retain images on the matching IDs', () {
    final rows = [
      for (final id in [30, 10, 20])
        {
          'id': id,
          'quiz_id': 7,
          'question_text': 'Question $id',
          'image_path': 'questions/image-$id.png',
        },
      {
        'id': 40,
        'quiz_id': 7,
        'question_text': 'Text only',
        'image_path': 'NULL',
      },
    ];
    final choices = [
      for (final id in [10, 20, 30, 40])
        {
          'id': id + 100,
          'question_id': id,
          'choice_text': 'Answer $id',
          'is_correct': true,
        },
    ];
    final study = buildStudyQuestions(questionRows: rows, choiceRows: choices);
    expect(study.map((q) => q.id), [10, 20, 30, 40]);
    final practice = buildQuestionBankPracticeQuestions(
      questionRows: rows,
      choiceRows: choices,
      random: Random(8),
    );
    for (final questions in [study, practice]) {
      expect(questions, hasLength(4));
      for (final q in questions) {
        expect(q.imagePath, q.id == 40 ? '' : 'questions/image-${q.id}.png');
        expect(q.choices.single.questiondId, q.id);
      }
    }
  });

  test(
    'question storage paths resolve to the admin bucket and preserve URLs',
    () {
      final resolved = resolveModuleFileUri(' questions/test image.png ')!;
      expect(
        resolved.path,
        '/storage/v1/object/public/admin/questions/test%20image.png',
      );
      const absolute = 'https://example.test/question.png?token=value';
      expect(resolveModuleFileUri(absolute).toString(), absolute);
    },
  );
}
