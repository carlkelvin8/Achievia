import 'dart:math';

import 'package:achievia/core/utils/question_bank_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('caps a randomized practice session at 20 usable questions', () {
    final questions = List.generate(
      25,
      (index) => {
        'id': index + 1,
        'quiz_id': 7,
        'question_text': 'Question ${index + 1}',
      },
    );
    final choices = List.generate(
      25,
      (index) => {
        'id': index + 100,
        'question_id': index + 1,
        'choice_text': 'Answer',
        'is_correct': true,
      },
    );

    final result = buildQuestionBankPracticeQuestions(
      questionRows: questions,
      choiceRows: choices,
      limit: 20,
      random: Random(1),
    );

    expect(result, hasLength(20));
    expect(result.map((question) => question.id).toSet(), hasLength(20));
    final repeated = buildQuestionBankPracticeQuestions(
      questionRows: questions,
      choiceRows: choices,
      limit: 20,
      random: Random(1),
    );
    final ids = result.map((question) => question.id).toList();
    expect(ids, repeated.map((question) => question.id).toList());
    expect(ids, isNot(List.generate(20, (index) => index + 1)));
  });

  test('drops questions without choices and keeps fewer than 20', () {
    final result = buildQuestionBankPracticeQuestions(
      questionRows: const [
        {'id': 1, 'question_text': 'Usable'},
        {'id': 2, 'question_text': 'No choices'},
      ],
      choiceRows: const [
        {'id': 10, 'question_id': 1, 'choice_text': 'A', 'is_correct': true},
      ],
      random: Random(1),
    );

    expect(result, hasLength(1));
    expect(result.single.id, 1);
    expect(result.single.choices.single.questiondId, 1);
  });

  test('calculates zero, partial, and perfect percentage scores', () {
    expect(questionBankScore(correct: 0, total: 0), 0);
    expect(questionBankScore(correct: 15, total: 20), 75);
    expect(questionBankScore(correct: 20, total: 20), 100);
  });
}
