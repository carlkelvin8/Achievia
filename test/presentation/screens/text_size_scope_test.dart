import 'dart:math';

import 'package:achievia/core/utils/content_text_scale.dart';
import 'package:achievia/data/repositoryImpl/progress/study_session_repository_impl.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart';
import 'package:achievia/domain/use_cases/progress/study_session_use_case.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/provider/reviewer/study_mode_provider.dart';
import 'package:achievia/presentation/provider/settings/settings_provider.dart';
import 'package:achievia/presentation/screens/question_bank/exam_summary_screen.dart';
import 'package:achievia/presentation/screens/question_bank/study_mode_screen.dart';
import 'package:achievia/presentation/widgets/cards/questions_content.dart';
import 'package:achievia/presentation/widgets/cards/questions_content_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/study_mode_fakes.dart';

/// A text size notifier that does not touch SharedPreferences.
class _FixedTextSize extends TextSizeNotifier {
  _FixedTextSize(double value) {
    state = value;
  }
}

Widget host(double sliderValue, Widget child, {double systemScale = 1}) {
  return ProviderScope(
    // A fresh scope per pump, otherwise the first slider value would stick.
    key: UniqueKey(),
    overrides: [
      textSizeProvider.overrideWith((ref) => _FixedTextSize(sliderValue)),
    ],
    child: MaterialApp(
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(systemScale)),
        child: c!,
      ),
      home: Scaffold(body: child),
    ),
  );
}

/// Laid-out width of a one-line piece of text (works for Text and for the
/// RichText that the HTML renderer produces).
double widthOf(WidgetTester tester, String text) {
  final finder = find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText() == text,
  );
  expect(finder, findsWidgets, reason: 'text "$text" not found');
  // The natural (unwrapped) width of the text itself, not of the block that
  // the HTML renderer stretches across the screen.
  return tester
      .renderObject<RenderParagraph>(finder.first)
      .getMaxIntrinsicWidth(double.infinity);
}

const _sizes = {'min': 0.0, 'default': 0.5, 'max': 1.0};

final _choices = [
  ChoiceEntity(id: 1, questiondId: 1, choiceText: 'Alpha', isCorrect: true),
  ChoiceEntity(id: 2, questiondId: 1, choiceText: 'Beta', isCorrect: false),
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Take an Exam / Mock Boards question screen (QuestionsContent)', () {
    Future<Map<String, double>> measure(
      WidgetTester tester,
      double slider, {
      double system = 1,
    }) async {
      await tester.pumpWidget(
        host(
          slider,
          Column(
            children: [
              const Text('Heading'),
              ElevatedButton(onPressed: () {}, child: const Text('NEXT')),
              Expanded(
                child: QuestionsContent(
                  questionText: 'Question',
                  choices: _choices,
                  selectedIndex: null,
                  onSelect: (_) {},
                ),
              ),
            ],
          ),
          systemScale: system,
        ),
      );
      await tester.pump();
      return {
        'heading': widthOf(tester, 'Heading'),
        'button': widthOf(tester, 'NEXT'),
        'question': widthOf(tester, 'Question'),
        'choice': widthOf(tester, 'Alpha'),
      };
    }

    testWidgets('question and choices follow the slider; the rest does not', (
      tester,
    ) async {
      final min = await measure(tester, _sizes['min']!);
      final def = await measure(tester, _sizes['default']!);
      final max = await measure(tester, _sizes['max']!);

      // Study content scales...
      for (final key in ['question', 'choice']) {
        expect(min[key], lessThan(def[key]!), reason: '$key min < default');
        expect(max[key], greaterThan(def[key]!), reason: '$key max > default');
        expect(
          max[key]! / def[key]!,
          closeTo(kContentScaleMax, 0.12),
          reason: '$key max ratio',
        );
        expect(
          min[key]! / def[key]!,
          closeTo(kContentScaleMin, 0.12),
          reason: '$key min ratio',
        );
      }
      // ...everything else is untouched.
      for (final key in ['heading', 'button']) {
        expect(min[key], def[key], reason: '$key at min');
        expect(max[key], def[key], reason: '$key at max');
      }
    });

    testWidgets('the system accessibility scale still applies on top', (
      tester,
    ) async {
      Future<(double, double)> at(double slider, double system) async {
        await tester.pumpWidget(
          host(
            slider,
            Column(
              children: [
                const Text('Heading'),
                QuestionsContentList(
                  questionText: 'Question',
                  choices: _choices,
                  selectedIndex: null,
                ),
              ],
            ),
            systemScale: system,
          ),
        );
        await tester.pump();
        return (widthOf(tester, 'Heading'), widthOf(tester, 'Question'));
      }

      final plain = await at(1.0, 1.0);
      final large = await at(1.0, 1.3);
      // The heading follows the OS scale only; the content follows both
      // (app factor 1.5 x system 1.3).
      expect(large.$1 / plain.$1, closeTo(1.3, 0.05));
      expect(large.$2 / plain.$2, closeTo(1.3, 0.05));
      final defaultSlider = await at(0.5, 1.3);
      expect(large.$2 / defaultSlider.$2, closeTo(1.5, 0.08));
    });

    testWidgets('large text with long content scrolls instead of clipping', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final longChoices = [
        for (var i = 0; i < 6; i++)
          ChoiceEntity(
            id: i + 1,
            questiondId: 1,
            choiceText: 'Choice $i ${'very long answer text ' * 12}',
            isCorrect: i == 0,
          ),
      ];
      await tester.pumpWidget(
        host(
          1.0,
          QuestionsContent(
            questionText: 'A long question. ${'More words. ' * 60}',
            choices: longChoices,
            selectedIndex: null,
            onSelect: (_) {},
          ),
          systemScale: 1.4,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      // Everything is reachable by scrolling.
      await tester.scrollUntilVisible(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().startsWith('Choice 5'),
        ),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Mock Board review list (QuestionsContentList)', () {
    testWidgets('question and choices follow the slider', (tester) async {
      Future<(double, double)> at(double slider) async {
        await tester.pumpWidget(
          host(
            slider,
            QuestionsContentList(
              questionText: 'Question',
              choices: _choices,
              selectedIndex: null,
            ),
          ),
        );
        await tester.pump();
        return (widthOf(tester, 'Question'), widthOf(tester, 'Alpha'));
      }

      final min = await at(0);
      final def = await at(0.5);
      final max = await at(1);
      expect(min.$1, lessThan(def.$1));
      expect(max.$1, greaterThan(def.$1));
      expect(min.$2, lessThan(def.$2));
      expect(max.$2, greaterThan(def.$2));
    });
  });

  group('Take an Exam summary', () {
    testWidgets('question and choices scale, labels do not', (tester) async {
      const item = ExamSummaryItem(
        position: 1,
        questionId: 1,
        questionText: 'Question',
        choices: [
          ExamSummaryChoice(id: 1, text: 'Alpha', isCorrect: true),
          ExamSummaryChoice(id: 2, text: 'Beta', isCorrect: false),
        ],
        selectedIndex: 1,
        correctIndex: 0,
      );
      Future<Map<String, double>> at(double slider) async {
        await tester.pumpWidget(
          host(
            slider,
            const SingleChildScrollView(
              child: ExamSummaryItemCard(item: item, total: 5),
            ),
          ),
        );
        await tester.pump();
        return {
          'question': widthOf(tester, 'Question'),
          'choice': widthOf(tester, 'Alpha'),
          'title': widthOf(tester, 'Question 1 of 5'),
          'status': widthOf(tester, 'Incorrect'),
        };
      }

      final min = await at(0);
      final def = await at(0.5);
      final max = await at(1);
      for (final key in ['question', 'choice']) {
        expect(min[key], lessThan(def[key]!));
        expect(max[key], greaterThan(def[key]!));
      }
      for (final key in ['title', 'status']) {
        expect(min[key], def[key]);
        expect(max[key], def[key]);
      }
    });
  });

  group('Study Deck', () {
    Widget app(double slider, FakeStudyRepo repo) {
      return ProviderScope(
        key: UniqueKey(),
        overrides: [
          textSizeProvider.overrideWith((ref) => _FixedTextSize(slider)),
          studyDeckRepositoryProvider.overrideWithValue(repo),
          studyProgressStoreProvider.overrideWithValue(MemoryStudyStore()),
          studyRandomProvider.overrideWithValue(Random(3)),
          studySessionUseCaseProvider.overrideWithValue(_NoopSessions()),
          activeAccountIdProvider.overrideWith((ref) => Stream.value('user-a')),
        ],
        child: const MaterialApp(
          home: StudyModeScreen(
            subject: QuestionBankSubject(
              id: 1,
              courseId: 1,
              title: 'Clinical Chemistry',
              description: '',
              image: '',
            ),
            topic: QuestionBankTopic(
              id: 10,
              subjectId: 1,
              title: 'Enzymes',
              description: '',
            ),
          ),
        ),
      );
    }

    testWidgets('question, choices and rationale scale; controls do not', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final questions = studyQuestions(1, base: 2);
      final repo = FakeStudyRepo({10: questions});

      Future<Map<String, double>> at(double slider) async {
        await tester.pumpWidget(app(slider, repo));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        await tester.pump();
        final q = questions.first;
        // Answer, then open the rationale.
        await tester.tap(
          find.byKey(ValueKey('study-choice-${q.choices.first.id}')),
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('study-rationale')));
        await tester.pump();
        double w(String text) => tester
            .renderObject<RenderParagraph>(
              find.textContaining(text, findRichText: true).first,
            )
            .getMaxIntrinsicWidth(double.infinity);
        return {
          'question': w(q.questionText),
          'choice': w(q.choices.first.choiceText),
          'rationale': w('Because reason'),
          'panelTitle': tester.getSize(find.text('Rationale').first).width,
        };
      }

      final min = await at(0);
      final def = await at(0.5);
      final max = await at(1);
      for (final key in ['question', 'choice', 'rationale']) {
        expect(min[key], lessThan(def[key]!), reason: key);
        expect(max[key], greaterThan(def[key]!), reason: key);
      }
      expect(min['panelTitle'], def['panelTitle']);
      expect(max['panelTitle'], def['panelTitle']);

      await tester.pumpWidget(const SizedBox());
    });
  });
}

class _NoopSessions implements StudySessionUseCase {
  @override
  StudySessionRepositoryImpl get repository => throw UnimplementedError();

  @override
  Future<void> recordSession({
    required DateTime startedAt,
    required DateTime endedAt,
    String sessionType = 'pomodoro',
  }) async {}
}
