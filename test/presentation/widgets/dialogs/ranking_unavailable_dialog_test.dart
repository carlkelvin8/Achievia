import 'package:achievia/presentation/widgets/dialogs/ranking_unavailable_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A page with one button that runs [confirmExamStart] and records whether the
/// exam would start.
Future<List<bool>> _pump(
  WidgetTester tester,
  Future<bool> Function() recordStart,
) async {
  final started = <bool>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                started.add(await confirmExamStart(context, recordStart));
              },
              child: const Text('START'),
            ),
          ),
        ),
      ),
    ),
  );
  return started;
}

void main() {
  testWidgets('a recorded start begins the exam without any warning', (
    tester,
  ) async {
    var calls = 0;
    final started = await _pump(tester, () async {
      calls++;
      return true;
    });

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    expect(started, [true]);
    expect(calls, 1);
    expect(find.text('Ranking unavailable'), findsNothing);
  });

  testWidgets('an unavailable server start warns BEFORE the exam begins', (
    tester,
  ) async {
    final started = await _pump(tester, () async => false);

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    // The exam has not started: the user is asked first.
    expect(started, isEmpty);
    expect(find.text('Ranking unavailable'), findsOneWidget);
    expect(
      find.textContaining('not be eligible for the leaderboard'),
      findsOneWidget,
    );
    expect(find.text('Continue without ranking'), findsOneWidget);
  });

  testWidgets('continuing accepts an unranked attempt', (tester) async {
    final started = await _pump(tester, () async => false);

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue without ranking'));
    await tester.pumpAndSettle();

    expect(started, [true]);
  });

  testWidgets('cancelling never starts the exam', (tester) async {
    final started = await _pump(tester, () async => false);

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(started, [false]);
  });

  testWidgets('try again records the start and begins without a warning', (
    tester,
  ) async {
    var calls = 0;
    final started = await _pump(tester, () async => ++calls >= 2);

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();
    expect(find.text('Ranking unavailable'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(started, [true]);
    expect(find.text('Ranking unavailable'), findsNothing);
  });
}
