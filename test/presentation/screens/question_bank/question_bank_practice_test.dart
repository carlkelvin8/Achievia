import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_practice_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('practice requires an answer before advancing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          questionBankQuestionsProvider(
            _topic.id,
          ).overrideWith((ref) async => _questions),
        ],
        child: const MaterialApp(
          home: QuestionBankPracticeScreen(selection: _selection),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
    var button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);

    await tester.tap(find.text('Wrong answer'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('choice-feedback-0')), findsOneWidget);
    button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('confirmed leave exits the practice route', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          questionBankQuestionsProvider(
            _topic.id,
          ).overrideWith((ref) async => _questions),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const QuestionBankPracticeScreen(
                        selection: _selection,
                      ),
                    ),
                  ),
                  child: const Text('Open practice'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Leave practice?'), findsOneWidget);

    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(find.text('Open practice'), findsOneWidget);
    expect(find.text('Leave practice?'), findsNothing);
  });
}

const _subject = QuestionBankSubject(
  id: 1,
  courseId: 4,
  title: 'Clinical Chemistry',
  description: '',
  image: '',
);
const _topic = QuestionBankTopic(
  id: 8,
  subjectId: 1,
  title: 'Enzymes',
  description: '',
);
const _selection = QuestionBankSelection(subject: _subject, topic: _topic);

final _questions = [
  QuestionItemEntity(
    id: 101,
    questionText: 'Question one',
    choices: [
      ChoiceEntity(
        id: 1,
        questiondId: 101,
        choiceText: 'Wrong answer',
        isCorrect: false,
      ),
      ChoiceEntity(
        id: 2,
        questiondId: 101,
        choiceText: 'Correct answer',
        isCorrect: true,
      ),
    ],
  ),
  QuestionItemEntity(
    id: 102,
    questionText: 'Question two',
    choices: [
      ChoiceEntity(
        id: 3,
        questiondId: 102,
        choiceText: 'Second answer',
        isCorrect: true,
      ),
    ],
  ),
];
