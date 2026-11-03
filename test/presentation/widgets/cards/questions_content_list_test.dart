import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/presentation/widgets/cards/questions_content_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ChoiceEntity _choice(int id, String text, {bool correct = false}) =>
    ChoiceEntity(id: id, choiceText: text, isCorrect: correct, questiondId: 1);

Future<void> _pump(WidgetTester tester, {required int? selectedIndex}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: QuestionsContentList(
            questionText: '1. Question',
            choices: [
              _choice(1, 'First'),
              _choice(2, 'Second', correct: true),
              _choice(3, 'Third'),
            ],
            selectedIndex: selectedIndex,
          ),
        ),
      ),
    ),
  );
}

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets('marks only the picked wrong answer red and the correct green', (
    tester,
  ) async {
    await _pump(tester, selectedIndex: 2);

    expect(_colorOf(tester, 'Second'), Colors.green);
    expect(_colorOf(tester, 'Third'), Colors.red);
    expect(_colorOf(tester, 'First'), isNot(Colors.red));
  });

  testWidgets('Achievia icons replace the radio circles', (tester) async {
    await _pump(tester, selectedIndex: 2);

    expect(find.byType(Radio<int>), findsNothing);
    expect(find.byKey(const ValueKey('mock-summary-icon-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('mock-summary-icon-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('mock-summary-icon-0')), findsNothing);
    // Every choice text starts at the same indent.
    final lefts = {
      for (final text in ['First', 'Second', 'Third'])
        tester.getTopLeft(find.text(text)).dx,
    };
    expect(lefts, hasLength(1));
  });

  testWidgets('renders italics, subscripts and the question image', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: QuestionsContentList(
              questionText:
                  '5. Infection with <em>Streptococcus pyogenes</em>?',
              imagePath: 'questions/smear.png',
              choices: [
                _choice(1, 'CO<sub>2</sub>', correct: true),
                _choice(2, '&lt;em&gt;Escaped&lt;/em&gt; tags'),
              ],
              selectedIndex: 0,
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('<', findRichText: true), findsNothing);
    final italic = <String>[];
    for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
      text.text.visitChildren((span) {
        if (span is TextSpan && span.style?.fontStyle == FontStyle.italic) {
          italic.add(span.text ?? '');
        }
        return true;
      });
    }
    expect(italic, containsAll(['Streptococcus pyogenes', 'Escaped']));
    expect(find.bySemanticsLabel('Question image'), findsOneWidget);
  });

  testWidgets('a skipped question shows the correct answer, nothing red', (
    tester,
  ) async {
    await _pump(tester, selectedIndex: null);

    expect(_colorOf(tester, 'Second'), Colors.green);
    expect(_colorOf(tester, 'First'), isNot(Colors.red));
    expect(_colorOf(tester, 'Third'), isNot(Colors.red));
  });

  testWidgets('shows the rationale under the choices when there is one', (
    tester,
  ) async {
    Future<void> pumpWith(String rationale) => tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuestionsContentList(
                questionText: '1. Question',
                rationale: rationale,
                choices: [_choice(1, 'First', correct: true)],
                selectedIndex: 0,
              ),
            ),
          ),
        ),
      ),
    );

    await pumpWith('<p>Grows best at 42 &deg;C.</p>');
    expect(find.text('Rationale'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mock-summary-rationale')),
      findsOneWidget,
    );

    await pumpWith('');
    expect(find.text('Rationale'), findsNothing);
  });
}
