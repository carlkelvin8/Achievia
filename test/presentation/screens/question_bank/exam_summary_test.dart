import 'dart:async';
import 'dart:math';

import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/data/data_source/reviewer/question_bank_remote_datasource.dart';
import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/repository/questions/question_bank_repository.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/screens/question_bank/exam_summary_screen.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

const subject = QuestionBankSubject(
  id: 1,
  courseId: 1,
  title: 'Clinical Chemistry',
  description: '',
  image: '',
);
const selection = QuestionBankSelection(subject: subject);

/// [n] distinct questions whose correct choice rotates through all four slots.
List<QuestionItemEntity> buildQuestions(int n, {int base = 1000}) => [
  for (var i = 0; i < n; i++)
    QuestionItemEntity(
      id: base + i,
      questionText: 'Question text ${base + i}',
      choices: [
        for (var c = 0; c < 4; c++)
          ChoiceEntity(
            id: (base + i) * 10 + c,
            questiondId: base + i,
            choiceText: 'Choice ${base + i}-$c',
            isCorrect: c == i % 4,
          ),
      ],
    ),
];

/// Answers the first [answered] questions; every 3rd of them wrongly.
Map<int, int> answersFor(List<QuestionItemEntity> qs, int answered) => {
  for (var i = 0; i < answered; i++) qs[i].id: i % 3 == 2 ? (i + 1) % 4 : i % 4,
};

QuestionBankAttempt attemptFor(
  ExamAttemptSnapshot snapshot, {
  String id = 'attempt-1',
  bool hasSummary = true,
}) => QuestionBankAttempt(
  id: id,
  userId: 'u',
  subjectId: 1,
  subjectTitle: 'Clinical Chemistry',
  topicTitle: subjectExamTitle,
  correctAnswers: snapshot.correctCount,
  totalQuestions: snapshot.items.length,
  score: snapshot.correctCount * 100 / snapshot.items.length,
  completedAt: DateTime.utc(2026, 10, 5),
  attemptType: QuestionBankAttempt.subjectExamType,
  hasSummary: hasSummary,
);

ExamAttemptSnapshot snapshotOf(int total, int answered, {int base = 1000}) {
  final qs = buildQuestions(total, base: base);
  return ExamAttemptSnapshot.fromSession(
    clientAttemptId: newClientAttemptId(),
    questions: qs,
    selectedAnswers: answersFor(qs, answered),
  );
}

class FakeRepo implements QuestionBankRepository {
  /// Persisted summaries per user, keyed by attempt id.
  final Map<String, Map<String, ExamAttemptSummary>> byUser = {};
  String user = 'user-a';
  Object? failWith;
  Completer<void>? gate;
  int summaryLoads = 0;
  int liveQuestionCalls = 0;

  /// Every stored attempt of any type, newest first, for recent-attempt
  /// queries. The filter runs before the limit, like the real query.
  final recentAttempts = <QuestionBankAttempt>[];
  final recentQueries = <({int limit, String? attemptType})>[];
  final saves = <ExamAttemptSnapshot?>[];
  Object? saveFailure;
  QuestionBankAttempt? saveResult;

  @override
  Future<ExamAttemptSummary> getExamSummary(String attemptId) async {
    summaryLoads++;
    await gate?.future;
    if (failWith != null) throw failWith!;
    final found = byUser[user]?[attemptId];
    if (found == null) {
      throw const ExamSummaryException(ExamSummaryFailure.notFound);
    }
    return found;
  }

  @override
  Future<QuestionBankAttempt> saveAttempt({
    required QuestionBankSelection selection,
    required int correctAnswers,
    required int totalQuestions,
    ExamAttemptSnapshot? snapshot,
  }) async {
    saves.add(snapshot);
    if (saveFailure != null) throw saveFailure!;
    return saveResult ?? attemptFor(snapshot!);
  }

  @override
  Future<List<QuestionBankSubject>> getAllSubjects() async => const [];
  @override
  Future<List<QuestionBankSubject>> getSubjectsForCourse(int id) async =>
      const [];
  @override
  Future<List<QuestionBankTopic>> getTopics(int id) async => const [];
  @override
  Future<List<QuestionItemEntity>> getPracticeQuestions(
    int quizId, {
    int limit = 20,
    Random? random,
  }) async {
    liveQuestionCalls++;
    return const [];
  }

  @override
  Future<List<QuestionItemEntity>> getSubjectExamQuestions(
    int subjectId, {
    int count = 100,
    Random? random,
  }) async {
    liveQuestionCalls++;
    return const [];
  }

  @override
  Future<List<QuestionBankAttempt>> getRecentAttempts({
    int limit = 5,
    String? attemptType,
  }) async {
    recentQueries.add((limit: limit, attemptType: attemptType));
    return [
      for (final a in recentAttempts)
        if (attemptType == null || a.attemptType == attemptType) a,
    ].take(limit).toList();
  }
}

final testUser = StateProvider<String?>((ref) => 'user-a');

Future<void> pumpSummary(
  WidgetTester t,
  ExamSummaryArgs args, {
  FakeRepo? repo,
  Size size = const Size(400, 900),
  double textScale = 1,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        questionBankRepositoryProvider.overrideWithValue(repo ?? FakeRepo()),
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
        home: ExamSummaryScreen(args: args),
      ),
    ),
  );
  await t.pumpAndSettle();
}

String? logoLabel(WidgetTester t, int position, int choice) {
  final finder = find.byKey(ValueKey('exam-summary-logo-$position-$choice'));
  if (finder.evaluate().isEmpty) return null;
  return (t.widget(finder) as dynamic).semanticsLabel as String?;
}

void main() {
  group('snapshot from a session', () {
    test('has exactly 100 items in original order with every answer', () {
      final qs = buildQuestions(100);
      final answers = answersFor(qs, 100);
      final snap = ExamAttemptSnapshot.fromSession(
        clientAttemptId: newClientAttemptId(),
        questions: qs,
        selectedAnswers: answers,
      );

      expect(snap.items, hasLength(100));
      expect([
        for (final i in snap.items) i.position,
      ], List.generate(100, (i) => i + 1));
      expect(
        [for (final i in snap.items) i.questionId],
        [for (final q in qs) q.id],
      );
      for (var i = 0; i < 100; i++) {
        final item = snap.items[i];
        expect(item.selectedIndex, answers[qs[i].id]);
        expect(item.correctIndex, i % 4);
        expect(item.isCorrect, answers[qs[i].id] == i % 4);
        expect(item.questionText, qs[i].questionText);
        expect(
          item.choices.map((c) => c.text),
          qs[i].choices.map((c) => c.choiceText),
        );
      }
      expect(snap.items.every((i) => i.isAnswered), isTrue);
    });

    test('a timeout keeps unanswered and skipped items as unanswered', () {
      final qs = buildQuestions(100);
      final snap = ExamAttemptSnapshot.fromSession(
        clientAttemptId: 'x',
        questions: qs,
        selectedAnswers: answersFor(qs, 40),
      );
      expect(snap.items, hasLength(100));
      final unanswered = snap.items.where(
        (i) => i.status == ExamItemStatus.unanswered,
      );
      expect(unanswered, hasLength(60));
      expect(
        unanswered.every((i) => !i.isCorrect && i.selectedIndex == null),
        isTrue,
      );
      // Unanswered items still identify the correct answer.
      expect(unanswered.every((i) => i.correctIndex >= 0), isTrue);
    });

    test('a question without a correct choice cannot be summarised', () {
      final bad = [
        QuestionItemEntity(
          id: 1,
          questionText: 'q',
          choices: [
            ChoiceEntity(
              id: 1,
              questiondId: 1,
              choiceText: 'a',
              isCorrect: false,
            ),
            ChoiceEntity(
              id: 2,
              questiondId: 1,
              choiceText: 'b',
              isCorrect: false,
            ),
          ],
        ),
      ];
      expect(
        () => ExamAttemptSnapshot.fromSession(
          clientAttemptId: 'x',
          questions: bad,
          selectedAnswers: const {},
        ),
        throwsStateError,
      );
    });

    test('rpc payload reports only session facts, never correctness', () {
      final snap = snapshotOf(4, 2);
      final answered = snap.items[0].toRpcJson();
      final unanswered = snap.items[3].toRpcJson();

      for (final json in [answered, unanswered]) {
        expect(json.keys.toSet(), {
          'position',
          'question_id',
          'selected_choice_id',
          'choice_order',
        });
      }
      expect(answered['position'], 1);
      expect(answered['question_id'], snap.items[0].questionId);
      expect(
        answered['selected_choice_id'],
        snap.items[0].choices[snap.items[0].selectedIndex!].id,
      );
      expect(answered['choice_order'], snap.items[0].choices.map((c) => c.id));
      expect(unanswered['selected_choice_id'], isNull);
    });

    test('the payload cannot be influenced by claimed correctness', () {
      ExamSummaryItem item({required int correctIndex, required bool flag}) =>
          ExamSummaryItem(
            position: 1,
            questionId: 7,
            questionText: 'q',
            choices: [
              ExamSummaryChoice(id: 1, text: 'a', isCorrect: flag),
              ExamSummaryChoice(id: 2, text: 'b', isCorrect: !flag),
            ],
            selectedIndex: 0,
            correctIndex: correctIndex,
          );
      // Same selection and order, opposite claimed correct answers.
      expect(
        item(correctIndex: 0, flag: true).toRpcJson(),
        item(correctIndex: 1, flag: false).toRpcJson(),
      );
    });

    test('grading follows the chosen option flag, like the live exam', () {
      final item = ExamSummaryItem(
        position: 1,
        questionText: 'q',
        choices: const [
          ExamSummaryChoice(text: 'a', isCorrect: true),
          ExamSummaryChoice(text: 'b', isCorrect: false),
          ExamSummaryChoice(text: 'c', isCorrect: true),
        ],
        selectedIndex: 2, // a second correct option still counts
        correctIndex: 0,
      );
      expect(item.isCorrect, isTrue);
      expect(item.status, ExamItemStatus.correct);
    });

    test('client attempt ids are unique v4 uuids', () {
      final ids = {for (var i = 0; i < 50; i++) newClientAttemptId()};
      expect(ids, hasLength(50));
      expect(
        ids.every(
          (id) => RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ).hasMatch(id),
        ),
        isTrue,
      );
    });
  });

  group('score reconciliation', () {
    test('a consistent summary passes for manual and timed exams', () {
      for (final answered in [100, 40, 0]) {
        final snap = snapshotOf(100, answered);
        expect(
          ExamSummaryValidator.validate(
            snap.items,
            savedCorrect: snap.correctCount,
            savedTotal: 100,
          ),
          isEmpty,
        );
        final s = snap.toSummary();
        expect(s.correct + s.incorrect + s.unanswered, 100);
        expect(s.unanswered, 100 - answered);
      }
    });

    test('mismatched counts, duplicates and bad order are reported', () {
      final snap = snapshotOf(10, 10);
      List<String> run(List<ExamSummaryItem> items, {int? correct}) =>
          ExamSummaryValidator.validate(
            items,
            savedCorrect: correct ?? items.where((i) => i.isCorrect).length,
            savedTotal: 10,
          );
      expect(run(snap.items, correct: 3), isNotEmpty);
      expect(run(snap.items.sublist(0, 9)), isNotEmpty);
      expect(run(snap.items.reversed.toList()), isNotEmpty);
      final dup = [...snap.items.sublist(0, 9)];
      dup.add(
        ExamSummaryItem(
          position: 10,
          questionId: snap.items[0].questionId,
          questionText: 'dup',
          choices: snap.items[0].choices,
          selectedIndex: null,
          correctIndex: 0,
        ),
      );
      expect(run(dup).any((m) => m.contains('more than once')), isTrue);
    });
  });

  group('persisted rows', () {
    List<Map<String, dynamic>> rowsFor(ExamAttemptSnapshot snap) => [
      for (final i in snap.items)
        {
          'position': i.position,
          'question_id': i.questionId,
          'question_text': i.questionText,
          'choices_snapshot': [
            for (final c in i.choices)
              {'id': c.id, 'text': c.text, 'is_correct': c.isCorrect},
          ],
          'selected_index': i.selectedIndex,
          'correct_index': i.correctIndex,
        },
    ];

    test('reconstructs the exact attempt from stored snapshots', () {
      final snap = snapshotOf(100, 70);
      final summary = examSummaryFromRows(
        attemptId: 'a1',
        rows: rowsFor(snap),
        savedCorrect: snap.correctCount,
        savedTotal: 100,
      );
      expect(summary.isPersisted, isTrue);
      expect(summary.items, hasLength(100));
      for (var i = 0; i < 100; i++) {
        expect(summary.items[i].questionText, snap.items[i].questionText);
        expect(summary.items[i].selectedIndex, snap.items[i].selectedIndex);
        expect(summary.items[i].correctIndex, snap.items[i].correctIndex);
        expect(summary.items[i].status, snap.items[i].status);
      }
    });

    test('image and rationale kept in the snapshot are read from it', () {
      final snap = snapshotOf(3, 3);
      final rows = rowsFor(snap)
        ..[0]['image_path'] = 'questions/smear.png'
        ..[0]['rationale'] = '<p>Because.</p>'
        ..[1]['image_path'] = null
        ..[1]['rationale'] = 'null';
      final summary = examSummaryFromRows(
        attemptId: 'a',
        rows: rows,
        savedCorrect: snap.correctCount,
        savedTotal: 3,
      );
      expect(summary.items[0].imagePath, 'questions/smear.png');
      expect(summary.items[0].rationale, '<p>Because.</p>');
      expect(summary.items[1].imagePath, isEmpty);
      expect(summary.items[1].rationale, isEmpty);
    });

    test('a null question_id (deleted live question) still renders', () {
      final snap = snapshotOf(3, 3);
      final rows = rowsFor(snap)..[1]['question_id'] = null;
      final summary = examSummaryFromRows(
        attemptId: 'a',
        rows: rows,
        savedCorrect: snap.correctCount,
        savedTotal: 3,
      );
      expect(summary.items[1].questionId, isNull);
      expect(summary.items[1].questionText, snap.items[1].questionText);
    });

    test('a subject exam with fewer than 100 stored rows is never valid', () {
      // 97 rows that are internally consistent and match the saved score.
      final snap = snapshotOf(97, 97);
      expect(
        () => examSummaryFromRows(
          attemptId: 'a',
          rows: rowsFor(snap),
          savedCorrect: snap.correctCount,
          savedTotal: 97,
          requiredCount: 100,
        ),
        throwsA(
          isA<ExamSummaryException>().having(
            (e) => e.failure,
            'failure',
            ExamSummaryFailure.malformed,
          ),
        ),
      );
      // The same rows pass when no fixed size is required.
      expect(
        examSummaryFromRows(
          attemptId: 'a',
          rows: rowsFor(snap),
          savedCorrect: snap.correctCount,
          savedTotal: 97,
        ).items,
        hasLength(97),
      );
    });

    test('rows that arrive in descending order are shown 1..N', () {
      final snap = snapshotOf(5, 5);
      final summary = examSummaryFromRows(
        attemptId: 'a',
        rows: rowsFor(snap).reversed.toList(),
        savedCorrect: snap.correctCount,
        savedTotal: 5,
      );
      expect(summary.items.map((i) => i.position), [1, 2, 3, 4, 5]);
      expect(summary.correct, snap.correctCount);
    });

    test(
      'malformed or inconsistent data throws instead of showing partial',
      () {
        final snap = snapshotOf(5, 5);
        void expectMalformed(List<Map<String, dynamic>> rows, {int? correct}) {
          expect(
            () => examSummaryFromRows(
              attemptId: 'a',
              rows: rows,
              savedCorrect: correct ?? snap.correctCount,
              savedTotal: 5,
            ),
            throwsA(
              isA<ExamSummaryException>().having(
                (e) => e.failure,
                'failure',
                ExamSummaryFailure.malformed,
              ),
            ),
          );
        }

        expectMalformed(rowsFor(snap)..[0]['choices_snapshot'] = 'nope');
        expectMalformed(rowsFor(snap)..removeAt(2));
        expectMalformed(rowsFor(snap), correct: snap.correctCount + 1);
        expectMalformed(rowsFor(snap)..[4]['correct_index'] = 9);
      },
    );
  });

  test('plainExamText strips html tags and decodes entities', () {
    expect(
      plainExamText('<em>Actinomyces israelii</em>'),
      'Actinomyces israelii',
    );
    expect(plainExamText('a<br/>b &amp; c'), 'a\nb & c');
    expect(plainExamText('x < y'), 'x < y');
  });

  group('session save', () {
    ProviderContainer containerWith(FakeRepo repo) {
      final container = ProviderContainer(
        overrides: [questionBankRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('saves the exact 100 item snapshot once and returns it', () async {
      final repo = FakeRepo();
      final container = containerWith(repo);
      container.listen(questionBankSessionProvider, (_, _) {});
      final qs = buildQuestions(100);
      final notifier = container.read(questionBankSessionProvider.notifier)
        ..start(selection: selection, questions: qs);
      notifier.answer(1);
      notifier.advance();
      notifier.skip();

      final first = notifier.complete();
      final second = notifier.complete();
      final completion = await first;
      await second;

      expect(repo.saves, hasLength(1));
      final saved = repo.saves.single!;
      expect(saved.items, hasLength(100));
      expect(saved.items[0].selectedIndex, 1);
      expect(saved.items[1].selectedIndex, isNull);
      expect(saved.items.map((i) => i.questionId), qs.map((q) => q.id));
      expect(completion.snapshot, same(saved));
      expect(completion.isSaved, isTrue);
    });

    test('a retry after failure reuses the same idempotency key', () async {
      final repo = FakeRepo()..saveFailure = Exception('offline');
      final container = containerWith(repo);
      container.listen(questionBankSessionProvider, (_, _) {});
      final notifier = container.read(questionBankSessionProvider.notifier)
        ..start(selection: selection, questions: buildQuestions(5));

      final failed = await notifier.complete();
      expect(failed.isSaved, isFalse);
      expect(failed.snapshot, isNotNull); // exact in-memory record survives

      repo.saveFailure = null;
      await notifier.retrySave();
      expect(repo.saves, hasLength(2));
      expect(repo.saves[0]!.clientAttemptId, repo.saves[1]!.clientAttemptId);
    });

    test(
      'a new session gets a new idempotency key; practice has none',
      () async {
        final repo = FakeRepo();
        final container = containerWith(repo);
        container.listen(questionBankSessionProvider, (_, _) {});
        final notifier = container.read(questionBankSessionProvider.notifier);
        notifier.start(selection: selection, questions: buildQuestions(3));
        await notifier.complete();
        notifier.start(selection: selection, questions: buildQuestions(3));
        await notifier.complete();
        expect(
          repo.saves[0]!.clientAttemptId,
          isNot(repo.saves[1]!.clientAttemptId),
        );

        notifier.start(
          selection: QuestionBankSelection(
            subject: subject,
            topic: const QuestionBankTopic(
              id: 3,
              subjectId: 1,
              title: 't',
              description: '',
            ),
          ),
          questions: buildQuestions(3),
        );
        repo.saveResult = attemptFor(snapshotOf(3, 3));
        await notifier.complete();
        expect(repo.saves.last, isNull);
      },
    );
  });

  group('score-only fallback classification', () {
    PostgrestException err(String code, [String message = 'boom']) =>
        PostgrestException(message: message, code: code);

    test('falls back only when the snapshot function is clearly missing', () {
      expect(isSnapshotFunctionMissing(err('PGRST202')), isTrue);
      expect(
        isSnapshotFunctionMissing(
          err(
            '42883',
            'function public.save_subject_exam_attempt(x) does not exist',
          ),
        ),
        isTrue,
      );
    });

    test('permission, RLS, validation and server errors stay real errors', () {
      for (final e in [
        err(
          '42501',
          'permission denied for function save_subject_exam_attempt',
        ),
        err('42501', 'new row violates row-level security policy'),
        err('22023', 'malformed exam item'),
        err('23514', 'check constraint violated'),
        err('28000', 'Not authenticated'),
        err('42883', 'operator does not exist: integer = text'),
        err('PGRST301', 'JWT expired'),
        err('XX000', 'internal error'),
      ]) {
        expect(isSnapshotFunctionMissing(e), isFalse, reason: e.message);
      }
    });
  });

  group('session idempotency key', () {
    test('is fixed for the whole session and matches what is saved', () async {
      final repo = FakeRepo();
      final container = ProviderContainer(
        overrides: [questionBankRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(questionBankSessionProvider, (_, _) {});
      final notifier = container.read(questionBankSessionProvider.notifier)
        ..start(selection: selection, questions: buildQuestions(10));
      String key() =>
          container.read(questionBankSessionProvider).clientAttemptId;
      final initial = key();
      expect(initial, isNotEmpty);

      notifier.answer(0);
      expect(key(), initial);
      notifier.advance();
      notifier.skip();
      notifier.skip();
      expect(key(), initial);

      // Timeout auto-submit and a repeated submit share the same path.
      await Future.wait([notifier.complete(), notifier.complete()]);
      expect(key(), initial);
      await notifier.retrySave();
      expect(repo.saves, hasLength(1));
      expect(repo.saves.single!.clientAttemptId, initial);
    });
  });

  group('summary screen', () {
    testWidgets('renders all 100 items lazily, numbered, in order', (t) async {
      final snap = snapshotOf(100, 100);
      await pumpSummary(t, ExamSummaryArgs(inMemory: snap.toSummary()));

      expect(find.text('Question 1 of 100'), findsOneWidget);
      expect(find.text('Question text 1000'), findsOneWidget);
      // Lazy: far items are not built until scrolled to.
      expect(find.text('Question 100 of 100'), findsNothing);
      await t.scrollUntilVisible(
        find.text('Question 100 of 100'),
        800,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('summary-list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('Question text 1099'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('correct answer: one green marker, labelled', (t) async {
      final qs = buildQuestions(1);
      final snap = ExamAttemptSnapshot.fromSession(
        clientAttemptId: 'x',
        questions: qs,
        selectedAnswers: {qs[0].id: 0},
      );
      await pumpSummary(t, ExamSummaryArgs(inMemory: snap.toSummary()));

      expect(find.text('Correct'), findsOneWidget);
      expect(logoLabel(t, 1, 0), 'Correct answer');
      expect(logoLabel(t, 1, 1), isNull);
      expect(find.text('Your answer · Correct'), findsNothing);
      expect(find.text('Your answer'), findsNothing);
      expect(find.text('Correct answer'), findsNothing);
    });

    testWidgets('wrong answer: red selected plus separate green correct', (
      t,
    ) async {
      final qs = buildQuestions(1);
      final snap = ExamAttemptSnapshot.fromSession(
        clientAttemptId: 'x',
        questions: qs,
        selectedAnswers: {qs[0].id: 2}, // correct is 0
      );
      await pumpSummary(t, ExamSummaryArgs(inMemory: snap.toSummary()));

      expect(find.text('Incorrect'), findsOneWidget);
      expect(logoLabel(t, 1, 2), 'Incorrect answer');
      expect(logoLabel(t, 1, 0), 'Correct answer');
      expect(find.text('Your answer · Incorrect'), findsNothing);
      expect(find.text('Correct answer'), findsNothing);
      // The selected answer stays the selected one; it is not replaced.
      expect(find.text('Choice 1000-2'), findsOneWidget);
    });

    testWidgets('unanswered: labelled, no selection, correct shown', (t) async {
      final snap = snapshotOf(2, 1);
      await pumpSummary(t, ExamSummaryArgs(inMemory: snap.toSummary()));

      expect(
        find.byKey(const ValueKey('exam-summary-unanswered-2')),
        findsOneWidget,
      );
      // Unanswered is shown as BOTH unanswered and incorrect.
      expect(find.text('Unanswered · Incorrect'), findsOneWidget);
      expect(find.text('Unanswered: 1'), findsOneWidget);
      expect(find.text('No answer selected'), findsOneWidget);
      // Only the correct choice is marked on an unanswered item.
      expect(logoLabel(t, 2, 1), 'Correct answer');
      expect(logoLabel(t, 2, 0), isNull);
      expect(logoLabel(t, 2, 2), isNull);
    });

    testWidgets('each item is labelled Correct, Incorrect or Unanswered · '
        'Incorrect', (t) async {
      final qs = buildQuestions(3);
      final snap = ExamAttemptSnapshot.fromSession(
        clientAttemptId: 'x',
        questions: qs,
        selectedAnswers: {
          qs[0].id: 0, // correct
          qs[1].id: 2, // wrong (correct is 0)
          // qs[2] unanswered
        },
      );
      await pumpSummary(t, ExamSummaryArgs(inMemory: snap.toSummary()));

      String status(int position) => t
          .widget<Text>(find.byKey(ValueKey('exam-summary-status-$position')))
          .data!;
      expect(status(1), 'Correct');
      expect(status(2), 'Incorrect');
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('exam-summary-status-3')),
        200,
      );
      expect(status(3), 'Unanswered · Incorrect');
      expect(
        find.byKey(const ValueKey('summary-unanswered-note')),
        findsOneWidget,
      );
      expect(
        find.text('Unanswered questions are counted as incorrect.'),
        findsOneWidget,
      );
    });

    testWidgets('no unanswered note when every question was answered', (
      t,
    ) async {
      final snap = snapshotOf(5, 5);
      await pumpSummary(t, ExamSummaryArgs(inMemory: snap.toSummary()));
      expect(
        find.byKey(const ValueKey('summary-unanswered-note')),
        findsNothing,
      );
      expect(find.textContaining('Unanswered ·'), findsNothing);
    });

    testWidgets('header counts reconcile to the total', (t) async {
      final snap = snapshotOf(100, 70);
      await pumpSummary(t, ExamSummaryArgs(inMemory: snap.toSummary()));
      final s = snap.toSummary();
      expect(s.correct + s.incorrect + s.unanswered, 100);
      expect(find.text('Unanswered: 30'), findsOneWidget);
      expect(find.text('Correct: ${s.correct}'), findsOneWidget);
    });

    testWidgets('is read-only: taps change nothing and save nothing', (
      t,
    ) async {
      final repo = FakeRepo();
      final snap = snapshotOf(3, 2);
      final summary = snap.toSummary();
      await pumpSummary(t, ExamSummaryArgs(inMemory: summary), repo: repo);

      await t.tap(find.text('Choice 1000-3'), warnIfMissed: false);
      await t.scrollUntilVisible(find.text('Choice 1002-1'), 200);
      await t.tap(find.text('Choice 1002-1'), warnIfMissed: false);
      await t.pump();

      expect(repo.saves, isEmpty);
      expect(repo.summaryLoads, 0);
      expect(summary.correct, snap.correctCount);
      expect(find.byType(RadioListTile<int>), findsNothing);
      expect(find.text('Next'), findsNothing);
      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('shows the question image, rationale and italic text', (
      t,
    ) async {
      const item = ExamSummaryItem(
        position: 1,
        questionId: 1,
        questionText: 'Optimal range for <em>Campylobacter</em> growth?',
        choices: [
          ExamSummaryChoice(text: '<em>C. jejuni</em>', isCorrect: true),
          ExamSummaryChoice(text: 'Other', isCorrect: false),
        ],
        selectedIndex: 0,
        correctIndex: 0,
        imagePath: 'questions/smear.png',
        rationale: '<p>Grows best at 42 °C.</p>',
      );
      await pumpSummary(
        t,
        const ExamSummaryArgs(
          inMemory: ExamAttemptSummary(attemptId: '', items: [item]),
        ),
      );

      expect(
        find.byKey(const ValueKey('exam-summary-image-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('exam-summary-rationale-1')),
        findsOneWidget,
      );
      expect(find.textContaining('<em>', findRichText: true), findsNothing);
      final italic = <String>[];
      for (final text in t.widgetList<RichText>(find.byType(RichText))) {
        text.text.visitChildren((span) {
          if (span is TextSpan && span.style?.fontStyle == FontStyle.italic) {
            italic.add(span.text ?? '');
          }
          return true;
        });
      }
      expect(italic, containsAll(['Campylobacter', 'C. jejuni']));
    });

    testWidgets('in-memory summary is flagged as not saved', (t) async {
      await pumpSummary(
        t,
        ExamSummaryArgs(inMemory: snapshotOf(2, 2).toSummary()),
      );
      expect(find.byKey(const ValueKey('summary-not-saved')), findsOneWidget);
    });

    testWidgets('long text at a large text scale does not overflow', (t) async {
      final long = 'Extraordinarily long wording ' * 25;
      final item = ExamSummaryItem(
        position: 1,
        questionId: 1,
        questionText: long,
        choices: [
          ExamSummaryChoice(text: long, isCorrect: true),
          ExamSummaryChoice(text: long, isCorrect: false),
        ],
        selectedIndex: 1,
        correctIndex: 0,
      );
      await pumpSummary(
        t,
        ExamSummaryArgs(
          inMemory: ExamAttemptSummary(attemptId: '', items: [item]),
        ),
        size: const Size(320, 700),
        textScale: 2,
      );
      expect(t.takeException(), isNull);
    });
  });

  group('persisted loading', () {
    testWidgets('shows loading, then the saved attempt', (t) async {
      final repo = FakeRepo()..gate = Completer<void>();
      final snap = snapshotOf(5, 5);
      repo.byUser['user-a'] = {'a1': snap.toSummary(attemptId: 'a1')};
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            questionBankRepositoryProvider.overrideWithValue(repo),
            activeAccountIdProvider.overrideWith(
              (ref) => Stream.value('user-a'),
            ),
          ],
          child: const MaterialApp(
            home: ExamSummaryScreen(args: ExamSummaryArgs(attemptId: 'a1')),
          ),
        ),
      );
      await t.pump();
      await t.pump();
      expect(find.byKey(const ValueKey('summary-loading')), findsOneWidget);

      repo.gate!.complete();
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('summary-loading')), findsNothing);
      expect(find.text('Question 1 of 5'), findsOneWidget);
      expect(find.byKey(const ValueKey('summary-not-saved')), findsNothing);
    });

    testWidgets('two attempts of the same subject stay independent', (t) async {
      final repo = FakeRepo();
      final older = snapshotOf(3, 3, base: 1000);
      final newer = snapshotOf(3, 1, base: 5000);
      repo.byUser['user-a'] = {
        'old': older.toSummary(attemptId: 'old'),
        'new': newer.toSummary(attemptId: 'new'),
      };

      await pumpSummary(t, const ExamSummaryArgs(attemptId: 'old'), repo: repo);
      expect(find.text('Question text 1000'), findsOneWidget);
      expect(find.text('Question text 5000'), findsNothing);

      await pumpSummary(t, const ExamSummaryArgs(attemptId: 'new'), repo: repo);
      expect(find.text('Question text 5000'), findsOneWidget);
      expect(find.text('Question text 1000'), findsNothing);
      expect(find.text('Unanswered: 2'), findsOneWidget);
    });

    testWidgets('missing, unavailable and malformed attempts fail safely', (
      t,
    ) async {
      for (final (failure, text) in [
        (ExamSummaryFailure.notFound, 'could not be found'),
        (ExamSummaryFailure.unavailable, 'older exam result'),
        (ExamSummaryFailure.malformed, 'inconsistent'),
      ]) {
        final repo = FakeRepo()..failWith = ExamSummaryException(failure);
        await pumpSummary(t, const ExamSummaryArgs(attemptId: 'x'), repo: repo);
        expect(find.byKey(const ValueKey('summary-error')), findsOneWidget);
        expect(find.textContaining(text), findsOneWidget);
        expect(find.byKey(const ValueKey('summary-list')), findsNothing);
      }
    });

    testWidgets('a repository failure shows a retry that recovers', (t) async {
      final repo = FakeRepo()..failWith = Exception('network');
      repo.byUser['user-a'] = {
        'a1': snapshotOf(3, 3).toSummary(attemptId: 'a1'),
      };
      await pumpSummary(t, const ExamSummaryArgs(attemptId: 'a1'), repo: repo);
      expect(find.byKey(const ValueKey('summary-error')), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);

      repo.failWith = null;
      await t.tap(find.byKey(const ValueKey('summary-retry')));
      await t.pumpAndSettle();
      expect(find.text('Question 1 of 3'), findsOneWidget);
    });

    testWidgets('no args at all is a safe error, not a crash', (t) async {
      await pumpSummary(t, const ExamSummaryArgs());
      expect(find.byKey(const ValueKey('summary-error')), findsOneWidget);
    });

    testWidgets('switching account never shows the previous user\'s summary', (
      t,
    ) async {
      final repo = FakeRepo();
      repo.byUser['user-a'] = {
        'a1': snapshotOf(3, 3).toSummary(attemptId: 'a1'),
      };
      await pumpSummary(t, const ExamSummaryArgs(attemptId: 'a1'), repo: repo);
      expect(find.text('Question 1 of 3'), findsOneWidget);

      // User B signs in: the repository (RLS) finds nothing for that id.
      repo.user = 'user-b';
      ProviderScope.containerOf(
        t.element(find.byType(ExamSummaryScreen)),
      ).read(testUser.notifier).state = 'user-b';
      await t.pumpAndSettle();

      expect(find.text('Question 1 of 3'), findsNothing);
      expect(find.byKey(const ValueKey('summary-error')), findsOneWidget);
    });
  });

  group('result page navigation', () {
    Future<GoRouter> pumpResult(
      WidgetTester t, {
      required QuestionBankResultArgs args,
      FakeRepo? repo,
    }) async {
      t.view.physicalSize = const Size(600, 2000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => QuestionBankResultScreen(args: args),
          ),
          GoRoute(
            path: RouteConstants.questionBankExamSummary,
            builder: (_, state) =>
                ExamSummaryScreen(args: state.extra! as ExamSummaryArgs),
          ),
        ],
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            questionBankRepositoryProvider.overrideWithValue(
              repo ?? FakeRepo(),
            ),
            activeAccountIdProvider.overrideWith(
              (ref) => Stream.value('user-a'),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await t.pumpAndSettle();
      return router;
    }

    testWidgets('saved exam opens the persisted summary by attempt id and '
        'back returns to the result', (t) async {
      final snap = snapshotOf(5, 4);
      final repo = FakeRepo();
      repo.byUser['user-a'] = {
        'attempt-1': snap.toSummary(attemptId: 'attempt-1'),
      };
      final router = await pumpResult(
        t,
        repo: repo,
        args: QuestionBankResultArgs(
          selection: selection,
          attempt: attemptFor(snap),
          isSaved: true,
          snapshot: snap,
        ),
      );

      await t.tap(find.byKey(const ValueKey('view-summary')));
      await t.pumpAndSettle();
      expect(find.text('Exam Summary'), findsOneWidget);
      expect(repo.summaryLoads, 1); // loaded by id, not from the snapshot
      expect(find.byKey(const ValueKey('summary-not-saved')), findsNothing);
      expect(repo.saves, isEmpty);

      router.pop();
      await t.pumpAndSettle();
      expect(find.text('Exam Results'), findsOneWidget);
      expect(repo.saves, isEmpty);
    });

    testWidgets('unsaved exam shows the exact in-memory summary, flagged, '
        'and never claims persistence', (t) async {
      final snap = snapshotOf(5, 4);
      final repo = FakeRepo();
      await pumpResult(
        t,
        repo: repo,
        args: QuestionBankResultArgs(
          selection: selection,
          attempt: attemptFor(snap, id: '', hasSummary: false),
          isSaved: false,
          snapshot: snap,
        ),
      );
      expect(find.text('Result not saved'), findsOneWidget);

      await t.tap(find.byKey(const ValueKey('view-summary')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('summary-not-saved')), findsOneWidget);
      expect(repo.summaryLoads, 0);
      expect(find.text('Question text 1000'), findsOneWidget);
      expect(repo.saves, isEmpty); // viewing never saves
    });

    testWidgets('score-only fallback save uses the in-memory summary', (
      t,
    ) async {
      final snap = snapshotOf(5, 4);
      final repo = FakeRepo();
      await pumpResult(
        t,
        repo: repo,
        args: QuestionBankResultArgs(
          selection: selection,
          attempt: attemptFor(snap, hasSummary: false), // saved, no items
          isSaved: true,
          snapshot: snap,
        ),
      );
      await t.tap(find.byKey(const ValueKey('view-summary')));
      await t.pumpAndSettle();
      expect(repo.summaryLoads, 0);
      expect(find.byKey(const ValueKey('summary-not-saved')), findsOneWidget);
    });

    testWidgets('practice results have no summary button', (t) async {
      final snap = snapshotOf(3, 3);
      await pumpResult(
        t,
        args: QuestionBankResultArgs(
          selection: QuestionBankSelection(
            subject: subject,
            topic: const QuestionBankTopic(
              id: 1,
              subjectId: 1,
              title: 't',
              description: '',
            ),
          ),
          attempt: attemptFor(snap),
          isSaved: true,
        ),
      );
      expect(find.byKey(const ValueKey('view-summary')), findsNothing);
    });

    testWidgets('a retry save resends the same exact snapshot', (t) async {
      final snap = snapshotOf(5, 4);
      final repo = FakeRepo();
      await pumpResult(
        t,
        repo: repo,
        args: QuestionBankResultArgs(
          selection: selection,
          attempt: attemptFor(snap, id: '', hasSummary: false),
          isSaved: false,
          snapshot: snap,
        ),
      );
      await t.tap(find.text('RETRY SAVE'));
      await t.pumpAndSettle();
      expect(repo.saves, [same(snap)]);
      expect(find.text('Result saved'), findsOneWidget);
    });
  });
}
