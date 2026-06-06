import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/provider/questions/questions_state.dart';
import 'package:achievia/presentation/widgets/cards/question_of_the_day_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class TestQuestionsProvider extends QuestionsProvider {
  @override
  AnswerQuestionNotifier build() {
    return AnswerQuestionNotifier(
      quiz_id: '',
      student_id: '',
      chosen_answer: '',
      isLoading: false,
    );
  }

  @override
  Future<void> answerQuestion(String chosenAnswer) async {}
}

void main() {
  testWidgets('renders choices from question of the day data', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getQoty.overrideWith(
            (ref) async => QotyEntity(
              quizId: 1,
              title: 'Daily Question',
              id: 10,
              questionText: 'Which answer is correct?',
              choices: [
                {'id': 1, 'choiceText': 'Choice A', 'is_correct': false},
                {'id': 2, 'choiceText': 'Choice B', 'is_correct': true},
              ],
            ),
          ),
          answerQotProvider.overrideWith(TestQuestionsProvider.new),
        ],
        child: const MaterialApp(home: Scaffold(body: QuestionOfTheDayCard())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Which answer is correct?'), findsOneWidget);
    expect(find.text('Choice A'), findsOneWidget);
    expect(find.text('Choice B'), findsOneWidget);
  });
}
