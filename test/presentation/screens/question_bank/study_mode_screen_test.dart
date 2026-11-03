import 'package:achievia/presentation/widgets/builders/inline_style_svg.dart';
import 'dart:math';

import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/answer_feedback.dart';
import 'package:achievia/data/repositoryImpl/progress/study_session_repository_impl.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/entities/widgets/pomodoro_state_entity.dart';
import 'package:achievia/domain/use_cases/progress/study_session_use_case.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/provider/reviewer/study_mode_provider.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_topics_screen.dart';
import 'package:achievia/presentation/screens/question_bank/study_mode_screen.dart';
import 'package:achievia/presentation/widgets/question_bank/question_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/study_mode_fakes.dart';

const subject = QuestionBankSubject(
  id: 1,
  courseId: 1,
  title: 'Clinical Chemistry',
  description: '',
  image: '',
);
const topic = QuestionBankTopic(
  id: 10,
  subjectId: 1,
  title: 'Enzymes',
  description: '',
);

class NoopStudySessions implements StudySessionUseCase {
  @override
  StudySessionRepositoryImpl get repository => throw UnimplementedError();

  @override
  Future<void> recordSession({
    required DateTime startedAt,
    required DateTime endedAt,
    String sessionType = 'pomodoro',
  }) async {}
}

final testUser = StateProvider<String?>((ref) => 'user-a');

class RecordingFeedback implements AnswerFeedbackOutput {
  final sounds = <bool>[];
  int vibrations = 0;

  @override
  Future<void> playSound({required bool correct}) async => sounds.add(correct);

  @override
  Future<void> vibrate() async => vibrations++;
}

class Rig {
  Rig({
    int count = 3,
    List<QuestionItemEntity>? questions,
    bool shuffle = false,
    this.feedback,
  }) : repo = FakeStudyRepo({10: questions ?? studyQuestions(count)});

  final FakeStudyRepo repo;
  final RecordingFeedback? feedback;
  final store = MemoryStudyStore();

  Future<void> pump(
    WidgetTester t, {
    Size size = const Size(400, 900),
    double textScale = 1,
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(_app(textScale));
    await t.pumpAndSettle(const Duration(milliseconds: 100));
    // Let the post-frame Pomodoro auto-start land.
    await t.pump();
  }

  Widget _app([double textScale = 1]) {
    return ProviderScope(
      key: UniqueKey(),
      overrides: [
        studyDeckRepositoryProvider.overrideWithValue(repo),
        studyProgressStoreProvider.overrideWithValue(store),
        studyRandomProvider.overrideWithValue(Random(3)),
        if (feedback != null)
          answerFeedbackOutputProvider.overrideWithValue(feedback!),
        studySessionUseCaseProvider.overrideWithValue(NoopStudySessions()),
        activeAccountIdProvider.overrideWith(
          (ref) => Stream.value(ref.watch(testUser)),
        ),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const StudyModeScreen(subject: subject, topic: topic),
      ),
    );
  }

  /// Pumps the screen once without settling, so tests can inspect every
  /// intermediate frame.
  Future<void> pumpRaw(WidgetTester t) async {
    await t.pumpWidget(_app());
  }

  /// Tears the screen down so the Pomodoro timer is cancelled before the
  /// test ends.
  Future<void> close(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
  }
}

String counter(String key) =>
    (find.byKey(ValueKey(key)).evaluate().single.widget as Text).data!;

Finder choice(int id) => find.byKey(ValueKey('study-choice-$id'));

/// Reads the semantics label of the Achievia logo next to a choice.
String? logoState(WidgetTester t, int id) {
  final f = find.byKey(ValueKey('study-logo-$id'));
  if (f.evaluate().isEmpty) return null;
  return t.widget<InlineStyleSvg>(f).semanticsLabel;
}

Future<void> tapKey(WidgetTester t, String key) async {
  await t.tap(find.byKey(ValueKey(key)));
  await t.pump();
}

/// Moves the timer to [phase] the way a finished session would: there is no
/// session picker in the UI any more, breaks start on their own.
Future<void> goToPhase(WidgetTester t, PomodoroPhase phase) async {
  final container = ProviderScope.containerOf(
    t.element(find.byType(StudyModeScreen)),
  );
  container.read(pomodoroProvider.notifier).selectPhase(phase);
  await t.pump();
}

Finder htmlText(String text) => find.textContaining(text, findRichText: true);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final questions = studyQuestions(3);
  final q1 = questions[0]; // correct choice: id%3 == 1 -> index 1

  group('answer feedback', () {
    // Choice ids are question * 10 + index; the correct index is question % 3.
    bool isCorrectId(int id) => id % 10 == (id ~/ 10) % 3;

    Future<int> tapFirstChoice(WidgetTester t) async {
      final key = find
          .byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key as ValueKey<String>).value.startsWith('study-choice-'),
          )
          .first;
      final id = int.parse(
        (t.widget(key).key as ValueKey<String>).value.split('-').last,
      );
      await t.tap(key);
      await t.pump();
      return id;
    }

    Future<int> tapChoiceWhere(WidgetTester t, bool correct) async {
      for (final w in t.widgetList(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key as ValueKey<String>).value.startsWith('study-choice-'),
        ),
      )) {
        final id = int.parse((w.key as ValueKey<String>).value.split('-').last);
        if (isCorrectId(id) == correct) {
          await t.tap(choice(id));
          await t.pump();
          return id;
        }
      }
      throw StateError('no choice');
    }

    testWidgets('correct answer: positive sound, never a vibration', (t) async {
      final out = RecordingFeedback();
      final rig = Rig(feedback: out);
      await rig.pump(t);
      await tapChoiceWhere(t, true);
      expect(out.sounds, [true]);
      expect(out.vibrations, 0);
      await rig.close(t);
    });

    testWidgets('incorrect answer: error sound and one vibration', (t) async {
      final out = RecordingFeedback();
      final rig = Rig(feedback: out);
      await rig.pump(t);
      await tapChoiceWhere(t, false);
      expect(out.sounds, [false]);
      expect(out.vibrations, 1);
      await rig.close(t);
    });

    testWidgets('a locked question gives feedback only once', (t) async {
      final out = RecordingFeedback();
      final rig = Rig(feedback: out);
      await rig.pump(t);
      final id = await tapFirstChoice(t);
      await t.tap(choice(id), warnIfMissed: false);
      await t.pump();
      expect(out.sounds, hasLength(1));
      await rig.close(t);
    });

    testWidgets('switches work independently', (t) async {
      final out = RecordingFeedback();
      final rig = Rig(feedback: out);
      await rig.pump(t);
      final container = ProviderScope.containerOf(
        t.element(find.byType(StudyModeScreen)),
      );
      await container.read(answerFeedbackProvider.notifier).setSounds(false);
      await tapChoiceWhere(t, false);
      expect(out.sounds, isEmpty, reason: 'sounds off');
      expect(out.vibrations, 1, reason: 'vibration is its own switch');
      await rig.close(t);
    });
  });

  testWidgets('question attachments follow the card when advancing the deck', (
    t,
  ) async {
    final cards = [
      for (final q in studyQuestions(3))
        QuestionItemEntity(
          id: q.id,
          questionText: q.questionText,
          choices: q.choices,
          imagePath: q.id == 3 ? '' : 'questions/image-${q.id}.png',
        ),
    ];
    final rig = Rig(questions: cards);
    await rig.pump(t);
    expect(
      t.widget<QuestionImage>(find.byType(QuestionImage)).imagePath,
      'questions/image-1.png',
    );
    expect(t.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
    await t.tap(choice(correctChoiceId(cards[0])));
    await t.pump();
    await tapKey(t, 'study-already-know');
    await t.pumpAndSettle();
    expect(
      t.widget<QuestionImage>(find.byType(QuestionImage)).imagePath,
      'questions/image-2.png',
    );
    await t.tap(choice(correctChoiceId(cards[1])));
    await t.pump();
    await tapKey(t, 'study-already-know');
    await t.pumpAndSettle();
    expect(find.byType(QuestionImage), findsNothing);
    expect(t.takeException(), isNull);
    await rig.close(t);
  });

  testWidgets('shows the first question, counters and only the counters', (
    t,
  ) async {
    final rig = Rig();
    await rig.pump(t);

    expect(htmlText('Study question 1'), findsOneWidget);
    expect(counter('study-remaining'), '3');
    expect(counter('study-repeat'), '0');
    expect(counter('study-done'), '0');
    for (final key in [
      'study-again',
      'study-rationale',
      'study-already-know',
    ]) {
      expect(find.byKey(ValueKey(key)), findsNothing);
    }
    // No exam controls or scoring anywhere.
    for (final text in ['Skip', 'Score', 'Next', 'View Result', 'Skipped']) {
      expect(find.text(text), findsNothing);
    }
    await rig.close(t);
  });

  testWidgets('correct answer: green logo on the selected choice, locked', (
    t,
  ) async {
    final rig = Rig();
    await rig.pump(t);
    await t.tap(choice(correctChoiceId(q1)));
    await t.pump();

    expect(logoState(t, correctChoiceId(q1)), 'Correct answer');
    expect(logoState(t, wrongChoiceId(q1)), isNull);
    // No text indicators: color coding and the Achievia icons only.
    expect(find.text('Your answer · Correct'), findsNothing);
    expect(find.text('Correct answer'), findsNothing);

    // Locked: another tap changes nothing.
    await t.tap(choice(wrongChoiceId(q1)));
    await t.pump();
    expect(logoState(t, wrongChoiceId(q1)), isNull);
    // Answered: the progress counters give way to the three logo buttons.
    expect(find.byKey(const ValueKey('study-remaining')), findsNothing);
    expect(find.byKey(const ValueKey('study-repeat')), findsNothing);
    expect(find.byKey(const ValueKey('study-done')), findsNothing);
    expect(find.byKey(const ValueKey('study-again')), findsOneWidget);
    expect(find.byKey(const ValueKey('study-rationale')), findsOneWidget);
    expect(find.byKey(const ValueKey('study-already-know')), findsOneWidget);
    expect(find.text('Study again'), findsOneWidget);
    expect(find.text('Rationale'), findsOneWidget);
    expect(find.text('Already know'), findsOneWidget);
    await rig.close(t);
  });

  testWidgets('wrong answer: red selected, green actual answer, no retry', (
    t,
  ) async {
    final rig = Rig();
    await rig.pump(t);
    await t.tap(choice(wrongChoiceId(q1)));
    await t.pump();

    expect(logoState(t, wrongChoiceId(q1)), 'Incorrect answer');
    expect(logoState(t, correctChoiceId(q1)), 'Correct answer');
    expect(find.text('Your answer · Incorrect'), findsNothing);
    expect(find.text('Correct answer'), findsNothing);

    await t.tap(choice(correctChoiceId(q1)));
    await t.pump();
    // Still the original (wrong) selection.
    expect(logoState(t, wrongChoiceId(q1)), 'Incorrect answer');
    expect(find.text('Your answer · Correct'), findsNothing);
    await rig.close(t);
  });

  testWidgets('post-answer actions appear only after answering', (t) async {
    final rig = Rig();
    await rig.pump(t);
    await t.tap(choice(correctChoiceId(q1)));
    await t.pump();
    expect(find.byKey(const ValueKey('study-again')), findsOneWidget);
    expect(find.byKey(const ValueKey('study-rationale')), findsOneWidget);
    expect(find.byKey(const ValueKey('study-already-know')), findsOneWidget);
    await rig.close(t);
  });

  testWidgets('Repeat and Done update at once and never double count', (
    t,
  ) async {
    final rig = Rig(count: 3);
    await rig.pump(t);
    // Study Again on question 1: it moves Remaining -> Repeat.
    await t.tap(choice(correctChoiceId(q1)));
    await t.pump();
    await tapKey(t, 'study-again');
    expect([counter('study-remaining'), counter('study-repeat')], ['2', '1']);
    expect(counter('study-done'), '0');

    // Already Know on questions 2 and 3.
    for (final q in [questions[1], questions[2]]) {
      await t.tap(choice(correctChoiceId(q)));
      await t.pump();
      await tapKey(t, 'study-already-know');
    }
    expect(counter('study-remaining'), '0');
    expect(counter('study-repeat'), '1');
    expect(counter('study-done'), '2');

    // Question 1 comes back; marking it Already Know moves it Repeat -> Done.
    await t.tap(choice(correctChoiceId(q1)));
    await t.pump();
    await tapKey(t, 'study-already-know');
    expect(find.text('Deck complete'), findsOneWidget);
    await rig.close(t);
  });

  testWidgets('Study Again: Repeat +1, question moves on and returns later', (
    t,
  ) async {
    final rig = Rig();
    await rig.pump(t);
    await t.tap(choice(correctChoiceId(q1)));
    await t.pump();
    await tapKey(t, 'study-again');

    expect(counter('study-repeat'), '1');
    expect(counter('study-remaining'), '2');
    expect(counter('study-done'), '0');
    expect(htmlText('Study question 2'), findsOneWidget);
    // Fresh, unanswered card.
    expect(find.byKey(const ValueKey('study-again')), findsNothing);
    await rig.close(t);
  });

  testWidgets(
    'Already Know: Remaining -1, Done +1, and it is not shown again',
    (t) async {
      final rig = Rig(count: 2);
      await rig.pump(t);
      await t.tap(choice(correctChoiceId(studyQuestions(2)[0])));
      await t.pump();
      await tapKey(t, 'study-already-know');

      expect(counter('study-remaining'), '1');
      expect(counter('study-done'), '1');
      expect(counter('study-repeat'), '0');

      // Study Again on the last active question keeps it (only one left).
      await t.tap(choice(correctChoiceId(studyQuestions(2)[1])));
      await t.pump();
      await tapKey(t, 'study-again');
      expect(htmlText('Study question 2'), findsOneWidget);
      expect(htmlText('Study question 1'), findsNothing);
      await rig.close(t);
    },
  );

  testWidgets('finishing the deck shows the completed state and Reset Deck', (
    t,
  ) async {
    final rig = Rig(count: 1);
    await rig.pump(t);
    await t.tap(choice(correctChoiceId(studyQuestions(1)[0])));
    await t.pump();
    await tapKey(t, 'study-already-know');

    expect(find.byKey(const ValueKey('study-complete')), findsOneWidget);
    expect(counter('study-remaining'), '0');
    expect(counter('study-done'), '1');
    expect(find.byKey(const ValueKey('study-again')), findsNothing);
    expect(find.byKey(const ValueKey('study-already-know')), findsNothing);

    await tapKey(t, 'study-reset-deck-complete');
    await t.tap(find.byKey(const ValueKey('study-reset-confirm')));
    await t.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('study-complete')), findsNothing);
    expect(counter('study-remaining'), '1');
    expect(counter('study-done'), '0');
    await rig.close(t);
  });

  testWidgets('rationale shows the stored text; missing shows a safe state', (
    t,
  ) async {
    // Question 2 has a rationale, question 1 does not.
    final rig = Rig();
    await rig.pump(t);
    await t.tap(choice(correctChoiceId(q1)));
    await t.pump();
    await tapKey(t, 'study-rationale');
    expect(find.byKey(const ValueKey('study-no-rationale')), findsOneWidget);
    await tapKey(t, 'study-already-know');

    final q2 = questions[1];
    await t.tap(choice(wrongChoiceId(q2)));
    await t.pump();
    expect(find.byKey(const ValueKey('study-rationale-panel')), findsNothing);
    await tapKey(t, 'study-rationale');
    expect(htmlText('Because reason 2'), findsOneWidget);
    // Opening it changed nothing else.
    expect(logoState(t, wrongChoiceId(q2)), 'Incorrect answer');
    // Counters are hidden while answered; Study Again brings them back.
    expect(find.byKey(const ValueKey('study-remaining')), findsNothing);
    await tapKey(t, 'study-again');
    expect(counter('study-done'), '1');
    expect(counter('study-repeat'), '1');
    await rig.close(t);
  });

  testWidgets('notes show below the last choice only when they exist', (
    t,
  ) async {
    final withNotes = QuestionItemEntity(
      id: 1,
      questionText: 'Study question 1',
      notes: 'Remember the three zones.',
      choices: [
        for (var c = 0; c < 4; c++)
          ChoiceEntity(
            id: 10 + c,
            questiondId: 1,
            choiceText: 'Option 1-$c',
            isCorrect: c == 1,
          ),
      ],
    );
    final rig = Rig(questions: [withNotes]);
    await rig.pump(t);
    final notes = find.byKey(const ValueKey('study-notes-panel'));
    expect(notes, findsOneWidget);
    expect(htmlText('Remember the three zones.'), findsOneWidget);
    // No "Notes" label, and the box is the gray surface (no border).
    expect(find.text('Notes'), findsNothing);
    final box = t.widget<Container>(
      find.byKey(const ValueKey('study-info-box')),
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.color, isNotNull);
    expect(decoration.border, isNull);
    // Directly below the last answer choice.
    final lastChoice = t.getRect(choice(13));
    expect(t.getRect(notes).top, greaterThan(lastChoice.bottom));
    expect(t.getRect(notes).top - lastChoice.bottom, lessThanOrEqualTo(24));
    await rig.close(t);

    final plain = Rig(count: 1);
    await plain.pump(t);
    expect(find.byKey(const ValueKey('study-notes-panel')), findsNothing);
    expect(find.text('Notes'), findsNothing);
    await plain.close(t);
  });

  group('disclaimer and rationale share one box', () {
    QuestionItemEntity withNotes(int id, {String notes = 'Disclaimer text.'}) {
      return QuestionItemEntity(
        id: id,
        questionText: 'Study question $id',
        notes: notes,
        rationale: 'Because reason $id',
        choices: [
          for (var c = 0; c < 3; c++)
            ChoiceEntity(
              id: id * 10 + c,
              questiondId: id,
              choiceText: 'Option $id-$c',
              isCorrect: c == 1,
            ),
        ],
      );
    }

    final box = find.byKey(const ValueKey('study-info-box'));

    testWidgets('Rationale replaces the disclaimer in the same box, and back', (
      t,
    ) async {
      final rig = Rig(questions: [withNotes(1), withNotes(2)]);
      await rig.pump(t);
      expect(htmlText('Disclaimer text.'), findsOneWidget);
      await t.tap(choice(11));
      await t.pump();
      final before = t.getRect(box);
      expect(htmlText('Disclaimer text.'), findsOneWidget);

      for (var i = 0; i < 3; i++) {
        await tapKey(t, 'study-rationale');
        expect(htmlText('Because reason 1'), findsOneWidget);
        expect(htmlText('Disclaimer text.'), findsNothing);
        expect(box, findsOneWidget, reason: 'still a single box');
        expect(t.getRect(box).topLeft, before.topLeft);
        expect(t.getRect(box).width, before.width);

        await tapKey(t, 'study-rationale');
        expect(htmlText('Disclaimer text.'), findsOneWidget);
        expect(htmlText('Because reason 1'), findsNothing);
        expect(t.getRect(box).topLeft, before.topLeft);
      }
      await rig.close(t);
    });

    testWidgets('a question without a disclaimer shows it where it would be', (
      t,
    ) async {
      final rig = Rig(questions: [withNotes(1, notes: '')]);
      await rig.pump(t);
      expect(box, findsNothing);
      await t.tap(choice(11));
      await t.pump();
      expect(box, findsNothing);

      await tapKey(t, 'study-rationale');
      expect(box, findsOneWidget);
      expect(htmlText('Because reason 1'), findsOneWidget);
      // Directly under the last choice, like the disclaimer would be.
      final last = t.getRect(choice(12));
      expect(t.getRect(box).top - last.bottom, lessThan(24));

      await tapKey(t, 'study-rationale');
      expect(box, findsNothing);
      await rig.close(t);
    });

    testWidgets('each question keeps its own disclaimer and rationale', (
      t,
    ) async {
      final rig = Rig(
        questions: [
          withNotes(1, notes: 'Note A'),
          withNotes(2, notes: 'Note B'),
        ],
      );
      await rig.pump(t);
      await t.tap(choice(11));
      await t.pump();
      await tapKey(t, 'study-rationale');
      expect(htmlText('Because reason 1'), findsOneWidget);
      await tapKey(t, 'study-again');

      // Next question starts on its own disclaimer, not the open rationale.
      expect(htmlText('Note B'), findsOneWidget);
      expect(htmlText('Because reason 1'), findsNothing);
      await t.tap(choice(21));
      await t.pump();
      await tapKey(t, 'study-rationale');
      expect(htmlText('Because reason 2'), findsOneWidget);
      expect(htmlText('Note B'), findsNothing);
      await rig.close(t);
    });
  });

  group('pomodoro layout', () {
    String time() =>
        (find
                    .byKey(const ValueKey('study-pomodoro-time'))
                    .evaluate()
                    .single
                    .widget
                as Text)
            .data!;

    String caption() =>
        (find
                    .byKey(const ValueKey('study-pomodoro-caption'))
                    .evaluate()
                    .single
                    .widget
                as Text)
            .data!;

    testWidgets('prominent timer, Pause and Reset, progress and 3 sessions', (
      t,
    ) async {
      final rig = Rig();
      await rig.pump(t);
      expect(find.byKey(const ValueKey('study-pomodoro-time')), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('study-pomodoro-reset')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('study-pomodoro-progress')),
        findsOneWidget,
      );
      // The session picker was removed: no Focus / Short Break / Long Break
      // chips on the screen.
      expect(find.text('Focus Session'), findsNothing);
      expect(find.text('Short Break'), findsNothing);
      expect(find.text('Long Break'), findsNothing);
      expect(caption(), 'Focus session');

      // The timer is horizontally aligned with its icon and buttons and sits
      // above the progress line.
      final timeBox = t.getRect(
        find.byKey(const ValueKey('study-pomodoro-time')),
      );
      final progress = t.getRect(
        find.byKey(const ValueKey('study-pomodoro-progress')),
      );
      expect(timeBox.bottom, lessThan(progress.top + 20));
      await rig.close(t);
    });

    testWidgets('choosing a session switches the countdown and caption', (
      t,
    ) async {
      final rig = Rig();
      await rig.pump(t);
      await goToPhase(t, PomodoroPhase.shortBreak);
      expect(caption(), 'Short break');
      expect(time(), '05:00');
      await goToPhase(t, PomodoroPhase.longBreak);
      expect(caption(), 'Long break');
      expect(time(), '30:00');
      await goToPhase(t, PomodoroPhase.focus);
      expect(caption(), 'Focus session');
      expect(time(), '25:00');
      await rig.close(t);
    });

    testWidgets(
      'a break shows the coffee icon and a red timer; focus restores',
      (t) async {
        final rig = Rig();
        await rig.pump(t);
        Color? timeColor() => t
            .widget<Text>(find.byKey(const ValueKey('study-pomodoro-time')))
            .style
            ?.color;
        final context = t.element(find.byType(StudyModeScreen));
        final error = Theme.of(context).colorScheme.error;
        final normal = timeColor();
        expect(normal, isNot(error));
        expect(find.byIcon(Icons.timer_outlined), findsOneWidget);

        for (final phase in [
          PomodoroPhase.shortBreak,
          PomodoroPhase.longBreak,
        ]) {
          await goToPhase(t, phase);
          expect(timeColor(), error, reason: '$phase');
          expect(find.byIcon(Icons.free_breakfast_outlined), findsOneWidget);
          expect(find.byIcon(Icons.timer_outlined), findsNothing);
        }

        await goToPhase(t, PomodoroPhase.focus);
        expect(timeColor(), normal, reason: 'original color restored');
        expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
        await rig.close(t);
      },
    );

    testWidgets('the progress line tracks the elapsed time', (t) async {
      final rig = Rig();
      await rig.pump(t);
      double value() => t
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('study-pomodoro-progress')),
          )
          .value!;
      expect(value(), closeTo(0, 0.01));
      await t.pump(const Duration(seconds: 150)); // 2.5 of 25 minutes
      expect(value(), closeTo(0.1, 0.02));
      await rig.close(t);
    });

    testWidgets('three counters are separated by vertical dividers', (t) async {
      final rig = Rig();
      await rig.pump(t);
      expect(find.byType(VerticalDivider), findsNWidgets(2));
      final r = t.getCenter(find.byKey(const ValueKey('study-remaining')));
      final p = t.getCenter(find.byKey(const ValueKey('study-repeat')));
      final d = t.getCenter(find.byKey(const ValueKey('study-done')));
      expect(p.dx - r.dx, closeTo(d.dx - p.dx, 8), reason: 'evenly spaced');
      await rig.close(t);
    });
  });

  group('break reminder prompt', () {
    final prompt = find.byKey(const ValueKey('study-break-prompt'));
    final backdrop = find.byKey(const ValueKey('study-break-backdrop'));

    Future<void> attempt(WidgetTester t, int id) async {
      await t.tap(choice(id), warnIfMissed: false);
      await t.pump();
    }

    testWidgets('shows the message when answering during a Short Break', (
      t,
    ) async {
      final rig = Rig();
      await rig.pump(t);
      await goToPhase(t, PomodoroPhase.shortBreak);
      await attempt(t, correctChoiceId(q1));

      expect(prompt, findsOneWidget);
      expect(find.text('Take a breather!'), findsOneWidget);
      expect(find.text('Rest up for the next focus session.'), findsOneWidget);
      // The answer was not registered: choices stay locked and unmarked.
      expect(logoState(t, correctChoiceId(q1)), isNull);
      expect(find.byKey(const ValueKey('study-again')), findsNothing);
      await rig.close(t);
    });

    testWidgets('the Long Break shows it too, and a focus session never does', (
      t,
    ) async {
      final rig = Rig();
      await rig.pump(t);
      await attempt(t, wrongChoiceId(q1));
      expect(prompt, findsNothing, reason: 'focus session answers normally');
      expect(logoState(t, wrongChoiceId(q1)), 'Incorrect answer');

      await tapKey(t, 'study-again');
      await goToPhase(t, PomodoroPhase.longBreak);
      // Whatever card is up now, answering is refused with the prompt.
      final shown = find
          .byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key as ValueKey<String>).value.startsWith('study-choice-'),
          )
          .first;
      await t.tap(shown, warnIfMissed: false);
      await t.pump();
      expect(prompt, findsOneWidget);
      await rig.close(t);
    });

    testWidgets('disappears by itself after about five seconds', (t) async {
      final rig = Rig();
      await rig.pump(t);
      await goToPhase(t, PomodoroPhase.shortBreak);
      await attempt(t, correctChoiceId(q1));
      await t.pump(const Duration(milliseconds: 4900));
      expect(prompt, findsOneWidget);
      await t.pump(const Duration(milliseconds: 200));
      expect(prompt, findsNothing);
      await rig.close(t);
    });

    testWidgets('a tap outside dismisses it at once, without answering', (
      t,
    ) async {
      final rig = Rig();
      await rig.pump(t);
      await goToPhase(t, PomodoroPhase.shortBreak);
      await attempt(t, correctChoiceId(q1));
      expect(prompt, findsOneWidget);

      // Tap on the dimmed area right where a choice is.
      await t.tapAt(t.getCenter(choice(wrongChoiceId(q1))));
      await t.pump();
      expect(prompt, findsNothing);
      expect(backdrop, findsNothing);
      expect(logoState(t, wrongChoiceId(q1)), isNull, reason: 'not answered');
      await rig.close(t);
    });

    testWidgets('appears again on every attempt and choices stay locked', (
      t,
    ) async {
      final rig = Rig();
      await rig.pump(t);
      await goToPhase(t, PomodoroPhase.shortBreak);
      for (var i = 0; i < 3; i++) {
        await attempt(t, correctChoiceId(q1));
        expect(prompt, findsOneWidget, reason: 'attempt ${i + 1}');
        await t.tapAt(const Offset(10, 10)); // dismiss
        await t.pump();
        expect(prompt, findsNothing);
        // Still locked after the prompt is gone.
        expect(logoState(t, correctChoiceId(q1)), isNull);
        expect(find.byKey(const ValueKey('study-remaining')), findsOneWidget);
      }
      await rig.close(t);
    });

    testWidgets('does not pause the timer or touch the progress', (t) async {
      final rig = Rig();
      await rig.pump(t);
      await goToPhase(t, PomodoroPhase.shortBreak);
      String time() =>
          (find
                      .byKey(const ValueKey('study-pomodoro-time'))
                      .evaluate()
                      .single
                      .widget
                  as Text)
              .data!;
      final before = time();
      await attempt(t, correctChoiceId(q1));
      await t.pump(const Duration(seconds: 3));
      expect(prompt, findsOneWidget);
      expect(time(), isNot(before), reason: 'the countdown kept running');
      expect(find.text('Pause'), findsOneWidget, reason: 'still running');
      expect(counter('study-remaining'), '3');
      expect(counter('study-done'), '0');
      await rig.close(t);
    });

    testWidgets('going back to Focus removes the prompt and unlocks answers', (
      t,
    ) async {
      final rig = Rig();
      await rig.pump(t);
      await goToPhase(t, PomodoroPhase.shortBreak);
      await attempt(t, correctChoiceId(q1));
      expect(prompt, findsOneWidget);
      // The prompt covers the screen, so switch through the notifier.
      final container = ProviderScope.containerOf(
        t.element(find.byType(StudyModeScreen)),
      );
      container
          .read(pomodoroProvider.notifier)
          .selectPhase(PomodoroPhase.focus);
      await t.pump();
      expect(prompt, findsNothing);
      await attempt(t, correctChoiceId(q1));
      expect(logoState(t, correctChoiceId(q1)), 'Correct answer');
      await rig.close(t);
    });
  });

  testWidgets('an empty subtopic shows a clean empty state and no Pomodoro', (
    t,
  ) async {
    final rig = Rig(count: 0);
    await rig.pump(t);
    expect(find.byKey(const ValueKey('study-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('study-pomodoro-time')), findsNothing);
    expect(find.byKey(const ValueKey('study-again')), findsNothing);
    expect(find.byKey(const ValueKey('study-remaining')), findsNothing);
    await rig.close(t);
  });

  testWidgets('a load failure shows Retry that recovers', (t) async {
    final rig = Rig()..repo.fail = true;
    await rig.pump(t);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byKey(const ValueKey('study-pomodoro-time')), findsNothing);
    rig.repo.fail = false;
    await t.tap(find.text('Retry'));
    await t.pumpAndSettle(const Duration(milliseconds: 100));
    expect(counter('study-remaining'), '3');
    await rig.close(t);
  });

  testWidgets('long question and choices at large text scale do not overflow', (
    t,
  ) async {
    final long = 'Extraordinarily long wording ' * 25;
    final rig = Rig(
      questions: [
        QuestionItemEntity(
          id: 1,
          questionText: long,
          choices: [
            ChoiceEntity(
              id: 11,
              questiondId: 1,
              choiceText: long,
              isCorrect: true,
            ),
            ChoiceEntity(
              id: 12,
              questiondId: 1,
              choiceText: long,
              isCorrect: false,
            ),
          ],
        ),
      ],
    );
    await rig.pump(t, size: const Size(320, 640), textScale: 2);
    await t.tap(choice(12));
    await t.pump();
    expect(t.takeException(), isNull);
    await rig.close(t);
  });

  group('settings', () {
    testWidgets('toggles persist per subtopic and Reset Deck confirms', (
      t,
    ) async {
      final rig = Rig(count: 4);
      await rig.pump(t);
      await tapKey(t, 'study-settings');
      await t.pumpAndSettle(const Duration(milliseconds: 100));
      await t.tap(find.byKey(const ValueKey('study-shuffle-questions')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('study-shuffle-choices')));
      await t.pump();
      await t.pumpAndSettle(const Duration(milliseconds: 100));
      final saved = rig.store.peek('user-a', 10)!;
      expect(saved.shuffleQuestions, isTrue);
      expect(saved.shuffleChoices, isTrue);

      // Reset Deck asks first; Cancel leaves everything alone.
      await t.tap(find.byKey(const ValueKey('study-reset-deck')));
      await t.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('Reset deck?'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle(const Duration(milliseconds: 100));
      expect(counter('study-remaining'), '4');
      await rig.close(t);
    });
  });

  group('pomodoro', () {
    testWidgets('auto-starts, pauses, resumes and resets', (t) async {
      final rig = Rig();
      await rig.pump(t);
      expect(find.text('Pause'), findsOneWidget); // running
      final start =
          (find
                      .byKey(const ValueKey('study-pomodoro-time'))
                      .evaluate()
                      .single
                      .widget
                  as Text)
              .data;
      await t.pump(const Duration(seconds: 3));
      final later =
          (find
                      .byKey(const ValueKey('study-pomodoro-time'))
                      .evaluate()
                      .single
                      .widget
                  as Text)
              .data;
      expect(later, isNot(start));

      await tapKey(t, 'study-pomodoro-toggle'); // pause
      expect(find.text('Resume'), findsOneWidget);
      final paused =
          (find
                      .byKey(const ValueKey('study-pomodoro-time'))
                      .evaluate()
                      .single
                      .widget
                  as Text)
              .data;
      await t.pump(const Duration(seconds: 5));
      expect(
        (find
                    .byKey(const ValueKey('study-pomodoro-time'))
                    .evaluate()
                    .single
                    .widget
                as Text)
            .data,
        paused,
      );

      await tapKey(t, 'study-pomodoro-toggle'); // resume
      expect(find.text('Pause'), findsOneWidget);
      await tapKey(t, 'study-pomodoro-reset');
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      await rig.close(t);
    });

    testWidgets('answers, Study Again, Already Know and Rationale never '
        'restart it', (t) async {
      final rig = Rig(count: 4);
      await rig.pump(t);
      await t.pump(const Duration(seconds: 10));
      String time() =>
          (find
                      .byKey(const ValueKey('study-pomodoro-time'))
                      .evaluate()
                      .single
                      .widget
                  as Text)
              .data!;
      final elapsed = time();
      expect(elapsed, isNot('25:00'));

      await t.tap(choice(correctChoiceId(q1)));
      await t.pump();
      await tapKey(t, 'study-rationale');
      await tapKey(t, 'study-again');
      final q2 = questions[1];
      await t.tap(choice(correctChoiceId(q2)));
      await t.pump();
      await tapKey(t, 'study-already-know');
      // Never jumped back to a fresh 25:00; only moved forward.
      expect(time(), isNot('25:00'));
      expect(find.text('Pause'), findsOneWidget);
      await rig.close(t);
    });

    testWidgets('rebuilds do not create a second timer, leaving stops it', (
      t,
    ) async {
      final rig = Rig();
      await rig.pump(t);
      final container = ProviderScope.containerOf(
        t.element(find.byType(StudyModeScreen)),
      );
      // A settings change rebuilds the screen; the clock still ticks once/sec.
      await t.pump(const Duration(seconds: 1));
      final a = container.read(pomodoroProvider).remaining;
      container
          .read(studyModeProvider((subjectId: 1, quizId: 10)).notifier)
          .setShuffleQuestions(true);
      await t.pump();
      await t.pump(const Duration(seconds: 4));
      final b = container.read(pomodoroProvider).remaining;
      expect(a - b, const Duration(seconds: 4));

      await rig.close(t);
      // Nothing is left ticking after the screen is gone.
      await t.pump(const Duration(seconds: 3));
    });
  });

  group('pomodoro uses the saved settings', () {
    void savedSettings() => SharedPreferences.setMockInitialValues({
      'pomodoro_focus_minutes': 40,
      'pomodoro_short_break_minutes': 7,
      'pomodoro_long_break_minutes': 20,
      'pomodoro_sessions_before_long': 3,
    });

    String time() =>
        (find
                    .byKey(const ValueKey('study-pomodoro-time'))
                    .evaluate()
                    .single
                    .widget
                as Text)
            .data!;

    testWidgets('starts at the saved focus duration, never at 25:00', (
      t,
    ) async {
      savedSettings();
      final rig = Rig();
      t.view.physicalSize = const Size(400, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await rig.pumpRaw(t);
      // Watch every frame until the timer appears: 25:00 must never show.
      for (var i = 0; i < 20; i++) {
        expect(find.text('25:00'), findsNothing);
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(time(), isNot('25:00'));
      expect(time(), anyOf('40:00', '39:59'));
      expect(find.text('Pause'), findsOneWidget);

      await t.pump(const Duration(seconds: 3));
      expect(time(), anyOf('39:56', '39:57', '39:58'));
      await rig.close(t);
    });

    testWidgets('all saved values are loaded and phases follow them', (
      t,
    ) async {
      savedSettings();
      final rig = Rig();
      await rig.pump(t);
      final container = ProviderScope.containerOf(
        t.element(find.byType(StudyModeScreen)),
      );
      final settings = container.read(pomodoroSettingsProvider);
      expect(settings.focusDuration, const Duration(minutes: 40));
      expect(settings.shortBreakDuration, const Duration(minutes: 7));
      expect(settings.longBreakDuration, const Duration(minutes: 20));
      expect(settings.sessionsBeforeLongBreak, 3);

      // A full focus session ends in the saved short break.
      await t.pump(const Duration(minutes: 40));
      expect(
        (find
                    .byKey(const ValueKey('study-pomodoro-caption'))
                    .evaluate()
                    .single
                    .widget
                as Text)
            .data,
        'Short break',
      );
      expect(time(), '07:00');
      await rig.close(t);
    });

    testWidgets('Reset returns to the saved focus duration', (t) async {
      savedSettings();
      final rig = Rig();
      await rig.pump(t);
      await t.pump(const Duration(seconds: 30));
      expect(time(), isNot('40:00'));
      await tapKey(t, 'study-pomodoro-reset');
      expect(time(), '40:00');
      expect(find.text('25:00'), findsNothing);
      expect(find.text('Resume'), findsOneWidget);
      await rig.close(t);
    });

    testWidgets('hydration does not start a second timer', (t) async {
      savedSettings();
      final rig = Rig();
      await rig.pump(t);
      final container = ProviderScope.containerOf(
        t.element(find.byType(StudyModeScreen)),
      );
      final a = container.read(pomodoroProvider).remaining;
      await t.pump(const Duration(seconds: 5));
      final b = container.read(pomodoroProvider).remaining;
      // Exactly one tick per second: a duplicate timer would double this.
      expect(a - b, const Duration(seconds: 5));
      await rig.close(t);
    });

    testWidgets('a study action does not touch the saved-duration timer', (
      t,
    ) async {
      savedSettings();
      final rig = Rig(count: 4);
      await rig.pump(t);
      await t.pump(const Duration(seconds: 10));
      final before = time();
      await t.tap(choice(correctChoiceId(q1)));
      await t.pump();
      await tapKey(t, 'study-again');
      expect(time(), before);
      await rig.close(t);
    });

    testWidgets('without saved settings the defaults still apply', (t) async {
      final rig = Rig();
      await rig.pump(t);
      expect(time(), anyOf('25:00', '24:59'));
      await rig.close(t);
    });
  });

  group('navigation', () {
    testWidgets('a subtopic opens study mode, not an exam or practice', (
      t,
    ) async {
      StudyModeArgs? received;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const QuestionBankTopicsScreen(subject: subject),
          ),
          GoRoute(
            path: RouteConstants.questionBankStudy,
            builder: (_, state) {
              received = state.extra as StudyModeArgs;
              return const Scaffold(body: Text('study screen'));
            },
          ),
          GoRoute(
            path: RouteConstants.questionBankPractice,
            builder: (_, _) => const Scaffold(body: Text('practice screen')),
          ),
        ],
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            questionBankTopicsProvider(1).overrideWith((ref) async => [topic]),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Enzymes'));
      await t.pumpAndSettle();
      expect(find.text('study screen'), findsOneWidget);
      expect(find.text('practice screen'), findsNothing);
      expect(received!.topic.id, 10);
      expect(received!.subject.id, 1);
    });
  });
}
