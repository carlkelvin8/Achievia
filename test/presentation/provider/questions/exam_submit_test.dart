import 'package:achievia/domain/use_cases/questions/questions_use_case.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeQuestionsUseCase implements QuestionsUseCase {
  _FakeQuestionsUseCase(this._submit);

  final Future<int> Function() _submit;
  int submitCalls = 0;

  @override
  Future<int> submitQuiz() {
    submitCalls++;
    return _submit();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Future<(ProviderContainer, BuildContext)> _pump(
  WidgetTester tester,
  _FakeQuestionsUseCase fake,
) async {
  final container = ProviderContainer(
    overrides: [getQuestions.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  late BuildContext captured;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            captured = context;
            return const Scaffold();
          },
        ),
      ),
    ),
  );
  return (container, captured);
}

void main() {
  testWidgets('a failing submit returns false instead of throwing', (
    tester,
  ) async {
    final fake = _FakeQuestionsUseCase(() async => throw Exception('offline'));
    final (container, context) = await _pump(tester, fake);

    final moved = await container
        .read(pageController.notifier)
        .next(context, 3, 2);
    await tester.pump();

    expect(moved, isFalse);
    expect(fake.submitCalls, 1);
  });

  testWidgets('an unsaved attempt (id <= 0) returns false', (tester) async {
    final fake = _FakeQuestionsUseCase(() async => 0);
    final (container, context) = await _pump(tester, fake);

    final moved = await container
        .read(pageController.notifier)
        .next(context, 1, 0);
    await tester.pump();

    expect(moved, isFalse);
  });

  testWidgets('a failed submit can be retried afterwards', (tester) async {
    var attempts = 0;
    final fake = _FakeQuestionsUseCase(() async {
      attempts++;
      throw Exception('still offline');
    });
    final (container, context) = await _pump(tester, fake);
    final notifier = container.read(pageController.notifier);

    expect(await notifier.next(context, 1, 0), isFalse);
    expect(await notifier.next(context, 1, 0), isFalse);
    await tester.pump();

    expect(attempts, 2);
  });
}
