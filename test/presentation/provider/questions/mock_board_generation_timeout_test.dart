import 'dart:async';

import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/domain/use_cases/questions/questions_use_case.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/widgets/dialogs/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Each call to [randomizeQuestions] is answered by the next queued result.
class _FakeQuestionsUseCase implements QuestionsUseCase {
  final results = <Future<List<QuestionsEntity>>>[];
  int calls = 0;

  @override
  Future<List<QuestionsEntity>> randomizeQuestions(int index) =>
      results[calls++];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final _subjects = [
  QuestionsEntity(
    id: '1',
    title: 'Hematology',
    courseId: '1',
    description: '',
    image: '',
    daySubject: null,
    createdAt: '',
  ),
];

void main() {
  testWidgets(
    'a timed-out generation fails, frees the button and allows a retry',
    (tester) async {
      final fake = _FakeQuestionsUseCase();
      final abandoned = Completer<List<QuestionsEntity>>();
      fake.results
        ..add(abandoned.future)
        ..add(Future.value(_subjects));

      final container = ProviderContainer(
        overrides: [getQuestions.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      late BuildContext context;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (c) {
                context = c;
                return const Scaffold();
              },
            ),
          ),
        ),
      );
      final notifier = container.read(answerQotProvider.notifier);

      final first = notifier.randomizeQuestion(0, context);
      await tester.pump();
      expect(find.byType(LoadingDialog), findsOneWidget);
      // A second tap while loading is ignored.
      expect(await notifier.randomizeQuestion(0, context), isFalse);
      expect(fake.calls, 1);

      // Just past the 60-second generation timeout.
      await tester.pump(const Duration(seconds: 61));
      expect(await first, isFalse);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.byType(LoadingDialog), findsNothing);
      expect(container.read(answerQotProvider).isLoading, isFalse);

      // Retry succeeds while the abandoned request is still pending.
      final retry = notifier.randomizeQuestion(0, context);
      await tester.pump();
      expect(await retry, isTrue);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      container.read(answeredQuestionsProvider.notifier).isAnswered(7);

      // The abandoned request finishing late changes nothing the UI owns.
      abandoned.complete(_subjects);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(container.read(answerQotProvider).isLoading, isFalse);
      expect(container.read(answeredQuestionsProvider), [7]);
      expect(find.byType(LoadingDialog), findsNothing);
      expect(fake.calls, 2);
    },
  );
}
