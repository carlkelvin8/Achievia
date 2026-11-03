import 'dart:math';

import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/question_bank_helpers.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/repository/questions/question_bank_repository.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_practice_screen.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_topics_screen.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _subject = QuestionBankSubject(
  id: 1,
  courseId: 1,
  title: 'Clinical Chemistry',
  description: '',
  image: '',
);

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

List<QuestionItemEntity> _questions(int n) => [
  for (var i = 1; i <= n; i++) _q(i),
];

class _FakeRepo implements QuestionBankRepository {
  _FakeRepo({this.examQuestions = const [], this.delay = Duration.zero});

  final List<QuestionItemEntity> examQuestions;
  final Duration delay;
  int examLoads = 0;
  final saved = <QuestionBankSelection>[];

  @override
  Future<List<QuestionItemEntity>> getSubjectExamQuestions(
    int subjectId, {
    int count = 100,
    Random? random,
  }) async {
    examLoads++;
    await Future<void>.delayed(delay);
    return examQuestions;
  }

  @override
  Future<ExamAttemptSummary> getExamSummary(String attemptId) async =>
      throw UnimplementedError();
  @override
  Future<QuestionBankAttempt> saveAttempt({
    required QuestionBankSelection selection,
    required int correctAnswers,
    required int totalQuestions,
    ExamAttemptSnapshot? snapshot,
  }) async {
    saved.add(selection);
    return QuestionBankAttempt(
      id: 'a${saved.length}',
      userId: 'u',
      subjectId: selection.subject.id,
      topicId: selection.topic?.id,
      subjectTitle: selection.subject.title,
      topicTitle: 'Subject Exam',
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      score: questionBankScore(correct: correctAnswers, total: totalQuestions),
      completedAt: DateTime.utc(2026, 1, 1),
      attemptType: selection.attemptType,
    );
  }

  @override
  Future<List<QuestionBankSubject>> getAllSubjects() async => const [];
  @override
  Future<List<QuestionBankSubject>> getSubjectsForCourse(int id) async =>
      const [];
  @override
  Future<List<QuestionBankTopic>> getTopics(int subjectId) async => const [
    QuestionBankTopic(id: 5, subjectId: 1, title: 'Enzymes', description: ''),
  ];
  @override
  Future<List<QuestionItemEntity>> getPracticeQuestions(
    int quizId, {
    int limit = 20,
    Random? random,
  }) async => const [];
  @override
  Future<List<QuestionBankAttempt>> getRecentAttempts({
    int limit = 5,
    String? attemptType,
  }) async => const [];
}

void main() {
  group('assembleExamQuestions', () {
    Future<List<QuestionItemEntity>> load(List<int> ids) async =>
        ids.map(_q).toList();

    test('picks exactly 100 distinct questions from many subtopics', () async {
      // ids 1-120 = subtopic A, 121-260 = subtopic B (same subject).
      final picked = await assembleExamQuestions(
        candidateIds: [for (var i = 1; i <= 260; i++) i, 5, 5, 130],
        loadUsable: load,
        random: Random(1),
      );
      expect(picked, hasLength(100));
      expect(picked.map((q) => q.id).toSet(), hasLength(100));
      expect(picked.any((q) => q.id <= 120), isTrue);
      expect(picked.any((q) => q.id > 120), isTrue);
    });

    test('skips unusable questions and still fills 100', () async {
      final picked = await assembleExamQuestions(
        candidateIds: [for (var i = 1; i <= 300; i++) i],
        loadUsable: (ids) async => ids.where((i) => i.isEven).map(_q).toList(),
        random: Random(2),
      );
      expect(picked, hasLength(100));
      expect(picked.every((q) => q.id.isEven), isTrue);
    });

    test('fewer than 100 usable returns fewer, never duplicates', () async {
      final picked = await assembleExamQuestions(
        candidateIds: [for (var i = 1; i <= 60; i++) i],
        loadUsable: load,
      );
      expect(picked, hasLength(60));
      expect(picked.map((q) => q.id).toSet(), hasLength(60));
    });

    test('selection is random between attempts', () async {
      final ids = [for (var i = 1; i <= 500; i++) i];
      final a = await assembleExamQuestions(
        candidateIds: ids,
        loadUsable: load,
        random: Random(1),
      );
      final b = await assembleExamQuestions(
        candidateIds: ids,
        loadUsable: load,
        random: Random(2),
      );
      expect(a.map((q) => q.id).toList(), isNot(b.map((q) => q.id).toList()));
    });
  });

  test('remaining time comes from the absolute deadline', () {
    final start = DateTime.utc(2026, 1, 1, 13);
    final end = start.add(subjectExamDuration);
    expect(remainingUntil(end, start), const Duration(minutes: 60));
    // Backgrounded from 1:15 to 1:25 PM: 35 minutes left, not 45.
    expect(
      remainingUntil(end, DateTime.utc(2026, 1, 1, 13, 25)),
      const Duration(minutes: 35),
    );
    expect(
      remainingUntil(end, end.add(const Duration(hours: 1))),
      Duration.zero,
    );
  });

  group('session', () {
    test(
      'exam session gets a 60 minute deadline and saves as subject_exam',
      () async {
        final repo = _FakeRepo();
        var now = DateTime.utc(2026, 1, 1, 13);
        final container = ProviderContainer(
          overrides: [
            questionBankRepositoryProvider.overrideWithValue(repo),
            questionBankClockProvider.overrideWithValue(() => now),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(questionBankSessionProvider.notifier);
        notifier.start(
          selection: const QuestionBankSelection(subject: _subject),
          questions: _questions(100),
          timeLimit: subjectExamDuration,
        );
        expect(
          container.read(questionBankSessionProvider).endsAt,
          DateTime.utc(2026, 1, 1, 14),
        );
        now = now.add(const Duration(minutes: 5));

        // 90 correct out of 100; double submit saves once.
        final questions = container.read(questionBankSessionProvider).questions;
        for (var i = 0; i < 100; i++) {
          notifier.answer(i < 90 ? 0 : 1);
          if (i < 99) notifier.next();
        }
        final results = await Future.wait([
          notifier.complete(),
          notifier.complete(),
        ]);
        expect(repo.saved, hasLength(1));
        expect(repo.saved.single.isSubjectExam, isTrue);
        expect(repo.saved.single.attemptType, 'subject_exam');
        expect(questions, hasLength(100));
        expect(results.first.attempt.correctAnswers, 90);
        expect(results.first.attempt.score, 90);
        expect(results.first.attempt.topicId, isNull);
      },
    );

    test('a subtopic selection is classified as practice', () {
      const topic = QuestionBankTopic(
        id: 5,
        subjectId: 1,
        title: 'Enzymes',
        description: '',
      );
      expect(
        const QuestionBankSelection(
          subject: _subject,
          topic: topic,
        ).attemptType,
        'practice',
      );
    });
  });

  group('screens', () {
    testWidgets('Take an Exam starts one exam; double tap does not stack', (
      tester,
    ) async {
      final repo = _FakeRepo(
        examQuestions: _questions(100),
        delay: const Duration(milliseconds: 200),
      );
      var pushes = 0;
      final router = GoRouter(
        initialLocation: '/topics',
        routes: [
          GoRoute(
            path: '/topics',
            builder: (_, _) =>
                const QuestionBankTopicsScreen(subject: _subject),
          ),
          GoRoute(
            path: RouteConstants.questionBankPractice,
            builder: (_, state) {
              pushes++;
              final args = state.extra as QuestionBankPracticeArgs;
              expect(args.selection.isSubjectExam, isTrue);
              expect(args.examQuestions, hasLength(100));
              return const Scaffold(body: Text('Exam started'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [questionBankRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Enzymes'), findsOneWidget);

      await tester.tap(find.text('TAKE AN EXAM'));
      await tester.pump();
      await tester.tap(find.byType(ReusableButton), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(repo.examLoads, 1);
      expect(pushes, 1);
      expect(find.text('Exam started'), findsOneWidget);
    });

    testWidgets('fewer than 100 questions does not start the exam', (
      tester,
    ) async {
      final repo = _FakeRepo(examQuestions: _questions(60));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [questionBankRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: QuestionBankTopicsScreen(subject: _subject),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('TAKE AN EXAM'));
      await tester.pumpAndSettle();
      expect(find.textContaining('not have enough questions'), findsOneWidget);
      expect(find.byType(QuestionBankTopicsScreen), findsOneWidget);
    });

    testWidgets('timer starts at 60:00 and expiry auto-submits once', (
      tester,
    ) async {
      final repo = _FakeRepo();
      var now = DateTime.utc(2026, 1, 1, 13);
      var resultsShown = 0;
      final router = GoRouter(
        initialLocation: '/exam',
        routes: [
          GoRoute(
            path: '/exam',
            builder: (_, _) => QuestionBankPracticeScreen(
              selection: const QuestionBankSelection(subject: _subject),
              examQuestions: _questions(100),
            ),
          ),
          GoRoute(
            path: RouteConstants.questionBankResults,
            builder: (_, state) {
              resultsShown++;
              final args = state.extra as QuestionBankResultArgs;
              expect(args.attempt.attemptType, 'subject_exam');
              return const Scaffold(body: Text('Results'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            questionBankRepositoryProvider.overrideWithValue(repo),
            questionBankClockProvider.overrideWithValue(() => now),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('60:00'), findsOneWidget);

      // Background for 25 minutes, then resume-style tick.
      now = now.add(const Duration(minutes: 25));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('35:00'), findsOneWidget);

      // Answer one question, then time runs out.
      await tester.tap(find.text('Right 1').first);
      await tester.pump();
      now = now.add(const Duration(minutes: 40));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Results'), findsOneWidget);
      expect(resultsShown, 1);
      expect(repo.saved, hasLength(1));
    });
  });
}
