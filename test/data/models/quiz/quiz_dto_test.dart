import 'package:achievia/data/models/quiz/quiz_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuizDto', () {
    test('parses nested choices that do not include questionId', () {
      final dto = QuizDto.fromJson({
        'quiz': [
          {
            'id': 1,
            'title': 'Clinical Chemistry',
            'description': '',
            'createdAt': '2026-06-06T00:00:00Z',
            'subjectId': 10,
            'questions': [
              {
                'id': 100,
                'questionText': 'Which option is correct?',
                'choices': [
                  {'id': 200, 'choiceText': 'Option A', 'is_correct': false},
                  {'id': 201, 'choiceText': 'Option B', 'is_correct': true},
                ],
              },
            ],
          },
        ],
      });

      final question = dto.items.single.questions.single;

      expect(question.choices, hasLength(2));
      expect(question.choices.first.choiceText, 'Option A');
      expect(question.choices.first.questionId, 100);
    });
  });
}
