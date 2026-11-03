import 'dart:math';

import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/repository/questions/question_bank_repository.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_practice_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _subject = QuestionBankSubject(
  id: 1,
  courseId: 1,
  title: 'Clinical Chemistry',
  description: '',
  image: '',
);

/// Choice 0 is correct, choice 1 is wrong.
QuestionItemEntity _q(int id) => QuestionItemEntity(
  id: id,
  questionText: 'Question $id',
  choices: [
    ChoiceEntity(
      id: id * 10,
      questiondId: id,
      choiceText: 'Right $id',
      isCorrect: true,
    ),
    ChoiceEntity(
      id: id * 10 + 1,
      questiondId: id,
      choiceText: 'Wrong $id',
      isCorrect: false,
    ),
  ],
);

class _Repo implements QuestionBankRepository {
  @override
  Future<ExamAttemptSummary> getExamSummary(String attemptId) async =>
      throw UnimplementedError();
  @override
  Future<QuestionBankAttempt> saveAttempt({
    required QuestionBankSelection selection,
    required int correctAnswers,
    required int totalQuestions,
    ExamAttemptSnapshot? snapshot,
  }) async => QuestionBankAttempt(
    id: 'a',
    userId: 'u',
    subjectId: 1,
    subjectTitle: 'x',
    topicTitle: 'x',
    correctAnswers: correctAnswers,
    totalQuestions: totalQuestions,
    score: 0,
    completedAt: DateTime.utc(2026),
    attemptType: 'subject_exam',
  );
  @override
  Future<List<QuestionBankSubject>> getAllSubjects() async => const [];
  @override
  Future<List<QuestionBankSubject>> getSubjectsForCourse(int id) async =>
      const [];
  @override
  Future<List<QuestionBankTopic>> getTopics(int subjectId) async => const [];
  @override
  Future<List<QuestionItemEntity>> getPracticeQuestions(
    int quizId, {
    int limit = 20,
    Random? random,
  }) async => const [];
  @override
  Future<List<QuestionItemEntity>> getSubjectExamQuestions(
    int subjectId, {
    int count = 100,
    Random? random,
  }) async => const [];
  @override
  Future<List<QuestionBankAttempt>> getRecentAttempts({
    int limit = 5,
    String? attemptType,
  }) async => const [];
}

Future<void> _pump(WidgetTester tester, int count) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        questionBankRepositoryProvider.overrideWithValue(_Repo()),
        questionBankClockProvider.overrideWithValue(
          () => DateTime.utc(2026, 1, 1),
        ),
      ],
      child: MaterialApp(
        home: QuestionBankPracticeScreen(
          selection: const QuestionBankSelection(subject: _subject),
          examQuestions: [for (var i = 1; i <= count; i++) _q(i)],
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

final _skip = find.text('SKIP');
final _next = find.text('NEXT');
final _viewResult = find.text('VIEW RESULT');
final _timer = find.byKey(const ValueKey('exam-timer'));

void _expectCountersVisible(bool visible) {
  for (final label in ['Remaining', 'Skipped', 'Score']) {
    expect(find.text(label), visible ? findsOneWidget : findsNothing);
  }
}

Future<void> _answer(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pump();
}

Color? _borderColor(WidgetTester tester, int index) {
  final container = tester.widget<AnimatedContainer>(
    find.byKey(ValueKey('choice-feedback-$index')),
  );
  return ((container.decoration as BoxDecoration).border as Border?)?.top.color;
}

void main() {
  testWidgets('before answering: Skip and counters, no Next', (tester) async {
    await _pump(tester, 3);
    expect(_skip, findsOneWidget);
    _expectCountersVisible(true);
    expect(_next, findsNothing);
    expect(_viewResult, findsNothing);
    expect(find.text('SUBMIT EXAM NOW'), findsNothing);
    expect(find.textContaining('Submit exam'), findsNothing);
    expect(_timer, findsOneWidget);
    expect(find.text('60:00'), findsOneWidget);
  });

  testWidgets(
    'correct answer: green text, green logo, Next replaces controls',
    (tester) async {
      await _pump(tester, 3);
      await _answer(tester, 'Right 1');

      expect(_skip, findsNothing);
      _expectCountersVisible(false);
      expect(_next, findsOneWidget);
      expect(_timer, findsOneWidget, reason: 'timer stays visible');
      expect(_borderColor(tester, 0), Colors.green.shade700);
      // The other choices are plain, with no icon.
      expect(find.byKey(const ValueKey('answer-logo-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('answer-logo-1')), findsNothing);
      expect(find.byKey(const ValueKey('answer-logo-2')), findsNothing);
    },
  );

  testWidgets('incorrect answer: red text and red logo', (tester) async {
    await _pump(tester, 3);
    await _answer(tester, 'Wrong 1');
    // The wrong pick is red with the X; the correct answer is shown green
    // with the check.
    expect(_borderColor(tester, 1), Colors.red.shade700);
    expect(_borderColor(tester, 0), Colors.green.shade700);
    expect(find.byKey(const ValueKey('answer-logo-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('answer-logo-0')), findsOneWidget);
  });

  testWidgets('timer is at the very top, Skip centered, dividers, no circles', (
    tester,
  ) async {
    await _pump(tester, 3);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;

    // 1. Timer inside the app bar, above everything else.
    final timer = tester.getRect(_timer);
    final appBar = tester.getRect(find.byType(AppBar));
    expect(timer.top, greaterThanOrEqualTo(appBar.top));
    expect(timer.bottom, lessThanOrEqualTo(appBar.bottom));

    // 2. Skip centered horizontally, neither tiny nor huge.
    final skip = tester.getRect(find.byKey(const ValueKey('exam-skip')));
    expect(skip.center.dx, closeTo(size.width / 2, 1));
    expect(skip.width, inInclusiveRange(110, 200));

    // 3. Two vertical dividers between Remaining, Skipped and Score.
    expect(find.byType(VerticalDivider), findsNWidgets(2));

    // 4. No selection circles beside the choices.
    expect(find.byType(RadioListTile<int>), findsNothing);
    expect(find.byType(Radio<int>), findsNothing);
  });

  testWidgets('after answering, all four choices stay aligned and equal', (
    tester,
  ) async {
    QuestionItemEntity four(int id) => QuestionItemEntity(
      id: id,
      questionText: 'Question $id',
      choices: [
        for (var c = 0; c < 4; c++)
          ChoiceEntity(
            id: id * 10 + c,
            questiondId: id,
            choiceText: c == 1 ? 'Right $id' : 'Option $c of $id',
            isCorrect: c == 1,
          ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [questionBankRepositoryProvider.overrideWithValue(_Repo())],
        child: MaterialApp(
          home: QuestionBankPracticeScreen(
            selection: const QuestionBankSelection(subject: _subject),
            examQuestions: [four(1), four(2)],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    Rect rect(int i) =>
        tester.getRect(find.byKey(ValueKey('choice-feedback-$i')));
    final before = [for (var i = 0; i < 4; i++) rect(i)];

    // Pick a wrong one: the X is shown on it and the check on the right one.
    await _answer(tester, 'Option 0 of 1');
    final after = [for (var i = 0; i < 4; i++) rect(i)];

    for (var i = 0; i < 4; i++) {
      expect(after[i].left, after.first.left, reason: 'tile $i left edge');
      expect(after[i].width, after.first.width, reason: 'tile $i width');
      expect(after[i].height.round(), after.first.height.round());
    }
    final gaps = {
      for (var i = 1; i < 4; i++) (after[i].top - after[i - 1].bottom).round(),
    };
    expect(gaps, hasLength(1), reason: 'consistent spacing');
    expect(after.first.left, before.first.left);

    // Text starts at the same x in all four tiles.
    final starts = {
      for (final label in [
        'Option 0 of 1',
        'Right 1',
        'Option 2 of 1',
        'Option 3 of 1',
      ])
        tester.getTopLeft(find.text(label)).dx.round(),
    };
    expect(starts, hasLength(1), reason: 'choice text aligned');
    expect(find.byKey(const ValueKey('answer-logo-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('answer-logo-1')), findsOneWidget);
  });

  testWidgets('answer is locked after the first selection', (tester) async {
    await _pump(tester, 3);
    await _answer(tester, 'Right 1');
    await _answer(tester, 'Wrong 1');
    // The later tap changed nothing: only the first answer is marked.
    expect(find.byKey(const ValueKey('answer-logo-1')), findsNothing);
    expect(find.byKey(const ValueKey('answer-logo-0')), findsOneWidget);
  });

  testWidgets('Next restores Skip and counters; rapid taps move one step', (
    tester,
  ) async {
    await _pump(tester, 3);
    await _answer(tester, 'Right 1');
    await tester.tap(_next);
    await tester.tap(_next, warnIfMissed: false);
    await tester.pump();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(_skip, findsOneWidget);
    _expectCountersVisible(true);
    expect(_next, findsNothing);
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('last question with nothing unanswered shows View Result', (
    tester,
  ) async {
    await _pump(tester, 2);
    await _answer(tester, 'Right 1');
    await tester.tap(_next);
    await tester.pump();
    await _answer(tester, 'Wrong 2');
    expect(_viewResult, findsOneWidget);
    expect(_next, findsNothing);
    _expectCountersVisible(false);
    expect(_timer, findsOneWidget);
  });

  testWidgets(
    'last question with skipped ones shows Next, then the final skipped '
    'question shows View Result',
    (tester) async {
      await _pump(tester, 3);
      await tester.tap(_skip); // Q1 skipped
      await tester.pump();
      await _answer(tester, 'Right 2');
      await tester.tap(_next);
      await tester.pump();
      await _answer(tester, 'Right 3'); // Question "100"
      expect(_next, findsOneWidget, reason: 'skipped questions remain');
      expect(_viewResult, findsNothing);

      await tester.tap(_next); // enters skipped review at the earliest skipped
      await tester.pump();
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.text('Reviewing skipped'), findsOneWidget);
      // Only one skipped left: no Skip, counters show Remaining 1, Skipped 1.
      expect(_skip, findsNothing);
      _expectCountersVisible(true);
      expect(find.text('1'), findsWidgets);

      await _answer(tester, 'Right 1');
      expect(_viewResult, findsOneWidget);
      expect(_next, findsNothing);
      _expectCountersVisible(false);
    },
  );
}
