import 'package:achievia/presentation/widgets/builders/question_jump_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestionJumpList(
            itemCount: 600,
            // Uneven heights, like real questions.
            itemBuilder: (context, index) => SizedBox(
              height: 80.0 + (index % 5) * 40,
              child: Text('Item $index'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('dragging shows the question indicator and jumps far away', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Item 0'), findsOneWidget);
    expect(find.byKey(const ValueKey('question-jump-indicator')), findsNothing);

    final track = find.byKey(const ValueKey('question-jump-track'));
    final top = tester.getTopLeft(track) + const Offset(14, 22);
    final gesture = await tester.startGesture(top);
    // About 70% down the track.
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(0, 520));
    await tester.pump();

    final indicator = find.byKey(const ValueKey('question-jump-indicator'));
    expect(indicator, findsOneWidget);
    final label = tester
        .widget<Text>(
          find.descendant(of: indicator, matching: find.byType(Text)),
        )
        .data!;
    final match = RegExp(r'^Question (\d+) of 600$').firstMatch(label);
    expect(match, isNotNull);
    final target = int.parse(match!.group(1)!) - 1;
    expect(target, greaterThan(300));

    await gesture.up();
    await tester.pumpAndSettle();

    // The indicator goes away and the chosen question sits at the top.
    expect(indicator, findsNothing);
    final item = find.text('Item $target');
    expect(item, findsOneWidget);
    expect(tester.getTopLeft(item).dy, moreOrLessEquals(0, epsilon: 1));
  });
}
