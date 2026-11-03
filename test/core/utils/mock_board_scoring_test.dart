import 'dart:math';

import 'package:achievia/core/utils/questions_helpers.dart';
import 'package:achievia/data/models/quiz/quiz_dto.dart';
import 'package:flutter_test/flutter_test.dart';

QuizDtoItems _section(int id, String title, int questions) => QuizDtoItems(
  id: id,
  title: title,
  description: '',
  createdAt: '',
  subjectId: id,
  questions: [
    for (var i = 0; i < questions; i++)
      QuestionsItemsDto(
        id: id * 1000 + i,
        questionText: 'q',
        choices: const [],
      ),
  ],
);

void main() {
  void reset() {
    resetMockBoardAnswers();
  }

  setUp(reset);
  tearDown(reset);

  test('unanswered questions count as wrong, not as a perfect score', () {
    final sections = [_section(1, 'A', 10)];
    for (var i = 0; i < 2; i++) {
      recordAnswer('A', true);
    }
    final payload = currentAnswerPayload(sections: sections);
    expect(payload.single['score'], 20.0);
  });

  test('payload follows section order, not the order of answering', () {
    final sections = [_section(1, 'A', 4), _section(2, 'B', 4)];
    recordAnswer('B', true);
    recordAnswer('A', true);
    final payload = currentAnswerPayload(sections: sections);
    expect(payload.map((e) => e['name']), ['A', 'B']);
  });

  test('a section that was never answered still gets an entry of 0', () {
    final sections = [_section(1, 'A', 4), _section(2, 'B', 4)];
    recordAnswer('A', true);
    final payload = currentAnswerPayload(sections: sections);
    expect(payload, hasLength(2));
    expect(payload[1]['score'], 0.0);
  });

  group('changing an answer', () {
    test('re-picking the same correct choice is counted once', () {
      final sections = [_section(1, 'A', 4)];
      recordAnswer('A', true, questionId: 1000, choiceId: 1);
      recordAnswer('A', true, questionId: 1000, choiceId: 1);
      final payload = currentAnswerPayload(sections: sections);
      expect(payload.single['score'], 25.0);
    });

    test('switching from a correct to a wrong choice removes the credit', () {
      final sections = [_section(1, 'A', 4)];
      recordAnswer('A', true, questionId: 1000, choiceId: 1);
      recordAnswer('A', false, questionId: 1000, choiceId: 2);
      final payload = currentAnswerPayload(sections: sections);
      expect(payload.single['score'], 0.0);
      expect(mockBoardSelections[1000], 2);
    });

    test('switching from a wrong to a correct choice gives credit once', () {
      final sections = [_section(1, 'A', 4)];
      recordAnswer('A', false, questionId: 1000, choiceId: 2);
      recordAnswer('A', true, questionId: 1000, choiceId: 1);
      final payload = currentAnswerPayload(sections: sections);
      expect(payload.single['score'], 25.0);
      expect(subjectScores['A']!.total, 1);
    });

    test('a new board starts clean after the tallies are cleared', () {
      recordAnswer('A', true, questionId: 1000, choiceId: 1);
      resetMockBoardAnswers();
      recordAnswer('A', false, questionId: 1000, choiceId: 2);
      expect(subjectScores['A']!.total, 1);
      expect(subjectScores['A']!.correct, 0);
    });
  });

  test('any tap sequence scores exactly the latest answer per question', () {
    // Two sections of 5 questions; choice 0 of every question is correct.
    final sections = [_section(1, 'A', 5), _section(2, 'B', 5)];
    final rng = Random(7);
    for (var run = 0; run < 200; run++) {
      resetMockBoardAnswers();
      final latest = <int, int>{};
      final taps = rng.nextInt(40);
      for (var t = 0; t < taps; t++) {
        final section = sections[rng.nextInt(sections.length)];
        final question = section.questions[rng.nextInt(5)];
        final choice = rng.nextInt(4);
        latest[question.id] = choice;
        recordAnswer(
          section.title,
          choice == 0,
          questionId: question.id,
          choiceId: question.id * 10 + choice,
        );
      }

      final payload = currentAnswerPayload(sections: sections);
      for (var i = 0; i < sections.length; i++) {
        final ids = sections[i].questions.map((q) => q.id).toSet();
        final answered = latest.keys.where(ids.contains);
        final correct = answered.where((id) => latest[id] == 0).length;
        final tally = subjectScores[sections[i].title];
        expect(tally?.total ?? 0, answered.length, reason: 'run $run');
        expect(tally?.correct ?? 0, correct, reason: 'run $run');
        // Unanswered questions count as wrong: rating is over all 5.
        expect(payload[i]['score'], correct / 5 * 100, reason: 'run $run');
        expect(payload[i]['score'], inInclusiveRange(0, 100));
      }
      expect(mockBoardSelections, {
        for (final e in latest.entries) e.key: e.key * 10 + e.value,
      });
    }
  });
}
