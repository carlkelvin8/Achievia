import 'dart:async';

import 'package:achievia/domain/entities/widgets/question_of_the_day_state.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:achievia/presentation/provider/questions/qotd_provider.dart';
import 'package:achievia/presentation/provider/task/local_day_provider.dart';
import 'package:achievia/presentation/widgets/cards/question_of_the_day_card.dart';
import 'package:achievia/presentation/widgets/question_bank/question_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/core/constants/app_assets.dart';
import 'package:achievia/presentation/widgets/builders/inline_style_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_qotd_repository.dart';

final now = DateTime.utc(2026, 3, 10, 2);

const singleQuestion = QotdDailyQuestion(
  questionId: 10,
  quizId: 5,
  questionText: 'Which answer is correct?',
  choices: [
    QotdChoice(id: 101, text: 'Choice A', isCorrect: false),
    QotdChoice(id: 102, text: 'Choice B', isCorrect: true),
  ],
);

const questionWithRationale = QotdDailyQuestion(
  questionId: 10,
  quizId: 5,
  questionText: 'Which answer is correct?',
  rationale: 'Albumin is the most abundant plasma protein.',
  choices: [
    QotdChoice(id: 101, text: 'Choice A', isCorrect: false),
    QotdChoice(id: 102, text: 'Choice B', isCorrect: true),
  ],
);

/// Green (correct) or red (incorrect) Achievia logo beside option [index].
String? logoState(WidgetTester tester, int index) => tester
    .widget<InlineStyleSvg>(find.byKey(ValueKey('qotd-logo-$index')))
    .semanticsLabel;

Future<FakeQotdRepository> pumpCard(
  WidgetTester tester,
  FakeQotdRepository repository, {
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        qotdRepositoryProvider.overrideWithValue(repository),
        activeAccountIdProvider.overrideWith((ref) => Stream.value('user-1')),
        taskClockProvider.overrideWithValue(() => now),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: const Scaffold(body: QuestionOfTheDayCard()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

FakeQotdRepository buildRepository({Map<int, QotdDailyQuestion>? questions}) {
  return FakeQotdRepository(
    eligibleQuestionIds: const {
      1: [10],
    },
    questions: questions ?? const {10: singleQuestion},
  );
}

void main() {
  testWidgets('branded check and X preserve answer text alignment', (
    tester,
  ) async {
    await pumpCard(tester, buildRepository());
    final leftA = tester.getTopLeft(find.text('Choice A')).dx;
    final leftB = tester.getTopLeft(find.text('Choice B')).dx;
    expect(leftA, leftB);
    await tester.tap(find.text('Choice A'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Choice A')).dx, leftA);
    expect(tester.getTopLeft(find.text('Choice B')).dx, leftB);
    expect(
      tester
          .widget<InlineStyleSvg>(find.byKey(const ValueKey('qotd-logo-0')))
          .assetPath,
      incorrectAnswerIcon,
    );
    expect(
      tester
          .widget<InlineStyleSvg>(find.byKey(const ValueKey('qotd-logo-1')))
          .assetPath,
      correctAnswerIcon,
    );
    final wrong = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('qotd-option-0')),
    );
    final correct = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('qotd-option-1')),
    );
    expect(
      (wrong.decoration as BoxDecoration).border!.top.color,
      Colors.red.shade700,
    );
    expect(
      (correct.decoration as BoxDecoration).border!.top.color,
      Colors.green.shade700,
    );
    expect(find.byKey(const ValueKey('qotd-feedback')), findsNothing);
  });

  testWidgets('circles show before answering and give way to check / X', (
    tester,
  ) async {
    await pumpCard(tester, buildRepository());
    // Before answering: one selection circle per choice.
    expect(find.byType(Radio<int>), findsNWidgets(2));
    final before = [
      for (var i = 0; i < 2; i++)
        tester.getRect(find.byKey(ValueKey('qotd-option-$i'))),
    ];

    await tester.tap(find.text('Choice A'));
    await tester.pumpAndSettle();

    // After answering: no circles at all, the Achievia icons replace them.
    expect(find.byType(Radio<int>), findsNothing);
    expect(find.byKey(const ValueKey('qotd-logo-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('qotd-logo-1')), findsOneWidget);

    // Tiles keep position, width and height; the text does not move.
    for (var i = 0; i < 2; i++) {
      final after = tester.getRect(find.byKey(ValueKey('qotd-option-$i')));
      expect(after.left, before[i].left);
      expect(after.width, before[i].width);
      expect(after.height, before[i].height);
    }
  });

  Color? rationaleColor(WidgetTester tester) =>
      (tester
                  .widget<Container>(
                    find.byKey(const ValueKey('qotd-rationale')),
                  )
                  .decoration
              as BoxDecoration)
          .color;

  testWidgets('rationale pulses briefly with its text continuously visible', (
    tester,
  ) async {
    await pumpCard(
      tester,
      buildRepository(questions: {10: questionWithRationale}),
    );
    await tester.tap(find.text('Choice B'));
    await tester.pump();
    final base = rationaleColor(tester);
    await tester.pump(const Duration(milliseconds: 225));
    expect(rationaleColor(tester), isNot(base));
    expect(find.text(questionWithRationale.rationale), findsOneWidget);
    await tester.pumpAndSettle();
    expect(rationaleColor(tester), base);
    expect(find.text(questionWithRationale.rationale), findsOneWidget);
  });

  testWidgets('rationale respects reduced motion', (tester) async {
    await pumpCard(
      tester,
      buildRepository(questions: {10: questionWithRationale}),
      disableAnimations: true,
    );
    await tester.tap(find.text('Choice B'));
    await tester.pump();
    final base = rationaleColor(tester);
    await tester.pump(const Duration(milliseconds: 225));
    expect(rationaleColor(tester), base);
    expect(find.text(questionWithRationale.rationale), findsOneWidget);
  });

  testWidgets('stored HTML rationale renders as readable explanation', (
    tester,
  ) async {
    final question = QotdDailyQuestion(
      questionId: singleQuestion.questionId,
      quizId: singleQuestion.quizId,
      questionText: singleQuestion.questionText,
      choices: singleQuestion.choices,
      rationale: '<p>Stored <strong>explanation</strong> of the answer.</p>',
    );
    await pumpCard(tester, buildRepository(questions: {10: question}));
    await tester.tap(find.text('Choice B'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Stored explanation', findRichText: true),
      findsOneWidget,
    );
    expect(find.text(question.rationale), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attachment loading does not hide the question or choices', (
    tester,
  ) async {
    const question = QotdDailyQuestion(
      questionId: 10,
      quizId: 5,
      questionText: 'Identify the picture',
      imagePath: 'questions/picture.png',
      choices: [
        QotdChoice(id: 101, text: 'Choice A', isCorrect: false),
        QotdChoice(id: 102, text: 'Choice B', isCorrect: true),
      ],
    );
    await pumpCard(tester, buildRepository(questions: {10: question}));
    expect(find.text('Identify the picture'), findsOneWidget);
    expect(find.text('Choice A'), findsOneWidget);
    expect(find.text('Choice B'), findsOneWidget);
    expect(
      tester.widget<QuestionImage>(find.byType(QuestionImage)).imagePath,
      question.imagePath,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the daily question with its subject and options', (
    tester,
  ) async {
    await pumpCard(tester, buildRepository());

    expect(find.text('CLINICAL CHEMISTRY'), findsOneWidget);
    expect(find.text('Which answer is correct?'), findsOneWidget);
    expect(find.text('Choice A'), findsOneWidget);
    expect(find.text('Choice B'), findsOneWidget);
    expect(find.byKey(const ValueKey('qotd-feedback')), findsNothing);
    expect(find.byKey(const ValueKey('qotd-rationale')), findsNothing);
  });

  testWidgets('answering shows correct feedback and locks the options', (
    tester,
  ) async {
    final repository = buildRepository();
    await pumpCard(tester, repository);

    await tester.tap(find.text('Choice B'));
    await tester.pumpAndSettle();

    expect(repository.submitted, hasLength(1));
    expect(repository.submitted.single.choiceId, 102);
    expect(find.text('Correct!'), findsNothing);
    expect(logoState(tester, 1), 'Correct answer');
    expect(find.byKey(const ValueKey('qotd-logo-0')), findsNothing);
    // A settled answer is not submittable again.
    await tester.tap(find.text('Choice A'));
    await tester.pumpAndSettle();
    expect(repository.submitted, hasLength(1));
  });

  testWidgets('a wrong answer is shown as incorrect and stays locked', (
    tester,
  ) async {
    final repository = buildRepository();
    await pumpCard(tester, repository);

    await tester.tap(find.text('Choice A'));
    await tester.pumpAndSettle();

    expect(repository.submitted.single.isCorrect, isFalse);
    expect(find.text('Incorrect'), findsNothing);
    // Red logo on the selected miss, green logo on the actual answer.
    expect(logoState(tester, 0), 'Incorrect answer');
    expect(logoState(tester, 1), 'Correct answer');
  });

  testWidgets('repeated taps while saving submit a single answer', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = buildRepository()..submitGate = gate;
    await pumpCard(tester, repository);

    await tester.tap(find.text('Choice B'));
    await tester.pump();
    await tester.tap(find.text('Choice A'));
    await tester.pump();
    expect(repository.submitted, isEmpty);

    gate.complete();
    await tester.pumpAndSettle();

    expect(repository.submitted, hasLength(1));
    expect(find.text('Correct!'), findsNothing);
  });

  testWidgets('a restored answer renders as answered without any interaction', (
    tester,
  ) async {
    final repository = buildRepository();
    repository.seedAnswer(
      questionId: 10,
      userId: 'user-1',
      choiceId: 101,
      isCorrect: false,
      answeredAt: DateTime.utc(2026, 3, 10, 4),
    );
    await pumpCard(tester, repository);

    expect(find.text('Incorrect'), findsNothing);
    expect(logoState(tester, 0), 'Incorrect answer');
    expect(logoState(tester, 1), 'Correct answer');

    await tester.tap(find.text('Choice B'));
    await tester.pumpAndSettle();
    expect(repository.submitted, isEmpty);
  });

  testWidgets('a failed save offers a retry and clears the error on retry', (
    tester,
  ) async {
    final repository = buildRepository()..failOnSubmit = true;
    await pumpCard(tester, repository);

    await tester.tap(find.text('Choice B'));
    await tester.pumpAndSettle();

    expect(repository.submitted, isEmpty);
    expect(find.byKey(const ValueKey('qotd-error')), findsOneWidget);
    expect(find.text('Correct!'), findsNothing);

    repository.failOnSubmit = false;
    await tester.tap(find.text('Choice B'));
    await tester.pumpAndSettle();

    expect(repository.submitted, hasLength(1));
    expect(find.byKey(const ValueKey('qotd-error')), findsNothing);
    expect(find.text('Correct!'), findsNothing);
  });

  testWidgets(
    'rationale is hidden until answered, then shows the stored text',
    (tester) async {
      await pumpCard(
        tester,
        buildRepository(questions: const {10: questionWithRationale}),
      );

      expect(find.byKey(const ValueKey('qotd-rationale')), findsNothing);
      expect(
        find.text('Albumin is the most abundant plasma protein.'),
        findsNothing,
      );

      await tester.tap(find.text('Choice A'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('qotd-rationale')), findsOneWidget);
      expect(find.text('Rationale'), findsOneWidget);
      expect(
        find.text('Albumin is the most abundant plasma protein.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('a persisted answer restores the rationale on load', (
    tester,
  ) async {
    final repository = buildRepository(
      questions: const {10: questionWithRationale},
    );
    repository.seedAnswer(
      questionId: 10,
      userId: 'user-1',
      choiceId: 102,
      isCorrect: true,
      answeredAt: DateTime.utc(2026, 3, 10, 4),
    );
    await pumpCard(tester, repository);

    expect(find.byKey(const ValueKey('qotd-rationale')), findsOneWidget);
    expect(logoState(tester, 1), 'Correct answer');
    expect(find.byKey(const ValueKey('qotd-logo-0')), findsNothing);
  });

  testWidgets('a missing rationale shows nothing and does not crash', (
    tester,
  ) async {
    await pumpCard(tester, buildRepository());
    await tester.tap(find.text('Choice B'));
    await tester.pumpAndSettle();

    expect(find.text('Correct!'), findsNothing);
    expect(find.byKey(const ValueKey('qotd-rationale')), findsNothing);
  });

  testWidgets('long text and a large text scale wrap without overflow', (
    tester,
  ) async {
    final long = 'Very long words ' * 30;
    final question = QotdDailyQuestion(
      questionId: 10,
      quizId: 5,
      questionText: long,
      rationale: long,
      choices: [
        QotdChoice(id: 101, text: long, isCorrect: false),
        QotdChoice(id: 102, text: long, isCorrect: true),
      ],
    );
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          qotdRepositoryProvider.overrideWithValue(
            buildRepository(questions: {10: question}),
          ),
          activeAccountIdProvider.overrideWith((ref) => Stream.value('user-1')),
          taskClockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(child: QuestionOfTheDayCard()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final radio = find.descendant(
      of: find.byKey(const ValueKey('qotd-option-0')),
      matching: find.byType(Radio<int>),
    );
    await tester.ensureVisible(radio);
    await tester.tap(radio);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('qotd-rationale')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a loading failure shows a retry that reloads the question', (
    tester,
  ) async {
    final repository = buildRepository()..failOnLoad = true;
    await pumpCard(tester, repository);

    expect(find.text('Unable to load today\'s question.'), findsOneWidget);
    expect(find.byKey(const ValueKey('qotd-retry')), findsOneWidget);

    repository.failOnLoad = false;
    await tester.tap(find.byKey(const ValueKey('qotd-retry')));
    await tester.pumpAndSettle();

    expect(find.text('Which answer is correct?'), findsOneWidget);
  });
}
