import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/presentation/widgets/cards/questions_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'allows choices below long question text to be scrolled into view',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 220,
              child: QuestionsContent(
                questionText: List.filled(60, 'Long question text').join(' '),
                choices: [
                  ChoiceEntity(
                    id: 1,
                    choiceText: 'Choice A',
                    isCorrect: false,
                    questiondId: 10,
                  ),
                  ChoiceEntity(
                    id: 2,
                    choiceText: 'Choice B',
                    isCorrect: true,
                    questiondId: 10,
                  ),
                ],
                selectedIndex: null,
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Scrollable), findsOneWidget);
    },
  );
}
