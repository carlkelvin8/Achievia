import 'package:achievia/core/utils/mock_board_progress.dart';
import 'package:achievia/core/utils/questions_helpers.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/use_cases/questions/questions_use_case.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/provider/questions/mock_board_resume.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/screens/main/exam_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoStore implements MockBoardProgressStore {
  @override
  Future<void> clear(String userId, bool isPreBoard) async {}
  @override
  Future<PendingMockBoard?> load(String userId, bool isPreBoard) async => null;
  @override
  Future<void> saveProgress(
    String userId,
    MockBoardProgress progress, {
    bool flush = false,
  }) async {}
  @override
  Future<void> saveSession(String u, bool p, MockBoardSession s) async {}
}

class _UseCase implements QuestionsUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

QuizItemEntity _subject(int id, String title) => QuizItemEntity(
  id: id,
  title: title,
  description: '',
  createdAt: '',
  subjectId: id,
  questions: [
    for (var q = 1; q <= 3; q++)
      QuestionItemEntity(
        id: id * 100 + q,
        questionText: '$title question $q',
        choices: [
          for (var c = 0; c < 4; c++)
            ChoiceEntity(
              id: (id * 100 + q) * 10 + c,
              choiceText: '$title Q$q choice $c',
              isCorrect: c == 0,
              questiondId: id * 100 + q,
            ),
        ],
      ),
  ],
);

Future<ProviderContainer> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  resetMockBoardAnswers();
  final container = ProviderContainer(
    overrides: [
      getQuestions.overrideWithValue(_UseCase()),
      getGeneratedQuestions.overrideWith(
        (ref) async => [
          _subject(1, 'Clinical Chemistry'),
          _subject(2, 'Hematology'),
        ],
      ),
      mockBoardProgressStoreProvider.overrideWithValue(_NoStore()),
      mockBoardUserIdProvider.overrideWithValue(() => null),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ExamScreen()),
    ),
  );
  container.read(timerProvider.notifier).start();
  await tester.pumpAndSettle();
  return container;
}

String _label(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('exam-question-label')))
    .data!;

void main() {
  testWidgets('Back / Next move freely and the navigator jumps', (
    tester,
  ) async {
    final container = await _pump(tester);
    expect(find.text('NAVIGATE'), findsOneWidget);
    expect(_label(tester), 'Question 1 of 3');

    // Next works without answering.
    await tester.tap(find.byKey(const ValueKey('exam-next')));
    await tester.pumpAndSettle();
    expect(_label(tester), 'Question 2 of 3');
    await tester.tap(find.byKey(const ValueKey('exam-prev')));
    await tester.pumpAndSettle();
    expect(_label(tester), 'Question 1 of 3');

    // The navigator opens; a number jumps straight to that question.
    await tester.tap(find.byKey(const ValueKey('exam-navigate')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('question-navigator')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('navigator-question-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('question-navigator')), findsNothing);
    expect(_label(tester), 'Question 3 of 3');
    expect(find.text('3. Clinical Chemistry question 3'), findsOneWidget);
    container.read(timerProvider.notifier).pause();
  });

  testWidgets('the check appears when all are answered and submits the '
      'subject to the next one with a fresh clock', (tester) async {
    final container = await _pump(tester);
    expect(find.byKey(const ValueKey('exam-submit-subject')), findsNothing);

    for (var q = 0; q < 3; q++) {
      await tester.tap(find.byKey(const ValueKey('choice-1')).first);
      await tester.pumpAndSettle();
      if (q < 2) {
        await tester.tap(find.byKey(const ValueKey('exam-next')));
        await tester.pumpAndSettle();
      }
    }
    // Let some time pass on the first subject's clock.
    await tester.pump(const Duration(seconds: 5));
    expect(
      container.read(timerProvider).remaining,
      lessThan(const Duration(minutes: mockBoardSubjectMinutes)),
    );

    await tester.tap(find.byKey(const ValueKey('exam-submit-subject')));
    await tester.pumpAndSettle();
    expect(find.text('Do you want to submit the exam?'), findsOneWidget);

    // Review Answers keeps the student on the subject.
    await tester.tap(find.byKey(const ValueKey('submit-subject-review')));
    await tester.pumpAndSettle();
    expect(find.text('Clinical Chemistry'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('exam-submit-subject')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('submit-subject-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Hematology'), findsOneWidget);
    expect(_label(tester), 'Question 1 of 3');
    expect(
      container.read(timerProvider).remaining,
      greaterThan(const Duration(minutes: mockBoardSubjectMinutes - 1)),
    );
    // Correctness was never shown during the exam.
    expect(mockBoardSelections.length, 3);
    container.read(timerProvider.notifier).pause();
  });
}
