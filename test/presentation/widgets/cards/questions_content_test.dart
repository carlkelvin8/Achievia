import 'dart:async';

import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/presentation/widgets/cards/questions_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('disables choices immediately while answer callback is pending', (
    tester,
  ) async {
    var selections = 0;
    final pendingAnswer = Completer<void>();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: QuestionsContent(
              questionText: 'Question',
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
              onSelect: (_) async {
                selections += 1;
                await pendingAnswer.future;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('choice-0')));
    await tester.tap(find.byKey(const ValueKey('choice-0')));
    await tester.pump();

    expect(selections, 1);

    pendingAnswer.complete();
  });

  testWidgets(
    'allows choices below long question text to be scrolled into view',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
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
        ),
      );

      expect(find.byType(Scrollable), findsOneWidget);
    },
  );
  testWidgets('shows visible red and green feedback after answering', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: QuestionsContent(
              questionText: 'Question',
              choices: [
                ChoiceEntity(
                  id: 1,
                  choiceText: 'Wrong answer',
                  isCorrect: false,
                  questiondId: 10,
                ),
                ChoiceEntity(
                  id: 2,
                  choiceText: 'Correct answer',
                  isCorrect: true,
                  questiondId: 10,
                ),
              ],
              selectedIndex: 0,
              onSelect: (_) {},
            ),
          ),
        ),
      ),
    );

    final wrongDecoration =
        tester
                .widget<AnimatedContainer>(
                  find.byKey(const ValueKey('choice-feedback-0')),
                )
                .decoration
            as BoxDecoration;
    final correctDecoration =
        tester
                .widget<AnimatedContainer>(
                  find.byKey(const ValueKey('choice-feedback-1')),
                )
                .decoration
            as BoxDecoration;

    expect(wrongDecoration.color, isNotNull);
    expect(correctDecoration.color, isNotNull);
    expect(wrongDecoration.color, isNot(correctDecoration.color));
  });

  testWidgets('Mock Boards selection: blue mark, changeable, no reveal', (
    tester,
  ) async {
    int? selected;
    final picks = <int>[];
    Widget build() => ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => QuestionsContent(
              questionText: 'Question',
              selectionOnly: true,
              choices: [
                for (var i = 0; i < 4; i++)
                  ChoiceEntity(
                    id: i,
                    choiceText: 'Choice $i',
                    isCorrect: i == 2,
                    questiondId: 10,
                  ),
              ],
              selectedIndex: selected,
              onSelect: (v) {
                picks.add(v!);
                setState(() => selected = v);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(build());

    await tester.tap(find.byKey(const ValueKey('choice-0')));
    await tester.pump();
    expect(find.byKey(const ValueKey('answer-logo-0')), findsOneWidget);
    // The correct answer is not revealed.
    expect(find.byKey(const ValueKey('answer-logo-2')), findsNothing);

    // The answer can be changed; the mark moves to the new choice.
    await tester.tap(find.byKey(const ValueKey('choice-3')));
    await tester.pump();
    expect(picks, [0, 3]);
    expect(find.byKey(const ValueKey('answer-logo-0')), findsNothing);
    expect(find.byKey(const ValueKey('answer-logo-3')), findsOneWidget);

    // All four choices start at the same indent.
    final lefts = {
      for (var i = 0; i < 4; i++) tester.getTopLeft(find.text('Choice $i')).dx,
    };
    expect(lefts, hasLength(1));
  });

  testWidgets('the question number sits on the same line as its text', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: QuestionsContent(
              // Stored by the admin panel as a paragraph (real row shape).
              questionText:
                  '18. <p>A trichrome-stained stool smear shows a bilaterally '
                  'symmetrical trophozoite.</p><p><br></p>',
              choices: [
                ChoiceEntity(
                  id: 1,
                  choiceText: 'Giardia intestinalis',
                  isCorrect: true,
                  questiondId: 18,
                ),
              ],
              selectedIndex: null,
              onSelect: (_) {},
            ),
          ),
        ),
      ),
    );
    final texts = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((r) => r.text.toPlainText().trim())
        .where((t) => t.contains('trichrome'))
        .toList();
    expect(texts, isNotEmpty);
    expect(texts.first, startsWith('18. A trichrome-stained stool smear'));
    expect(texts, isNot(contains('18.')));
  });
}
