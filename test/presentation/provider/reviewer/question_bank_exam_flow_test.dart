import 'dart:math';

import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/question_bank_helpers.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/repository/questions/question_bank_repository.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_practice_screen.dart';
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
const _selection = QuestionBankSelection(subject: _subject);

/// Choice 0 is always the correct one.
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

List<QuestionItemEntity> _qs(int n) => [for (var i = 1; i <= n; i++) _q(i)];

class _Repo implements QuestionBankRepository {
  final saved = <int>[];
  final progressSaves = <QuestionBankSelection>[];

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
    saved.add(correctAnswers);
    progressSaves.add(selection);
    return QuestionBankAttempt(
      id: 'a',
      userId: 'u',
      subjectId: selection.subject.id,
      subjectTitle: selection.subject.title,
      topicTitle: 'Subject Exam',
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      score: questionBankScore(correct: correctAnswers, total: totalQuestions),
      completedAt: DateTime.utc(2026),
      attemptType: selection.attemptType,
    );
  }

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

({ProviderContainer c, QuestionBankSessionNotifier n, _Repo repo}) _exam(
  int count,
) {
  final repo = _Repo();
  final c = ProviderContainer(
    overrides: [questionBankRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  final n = c.read(questionBankSessionProvider.notifier);
  n.start(
    selection: _selection,
    questions: _qs(count),
    timeLimit: subjectExamDuration,
  );
  return (c: c, n: n, repo: repo);
}

QuestionBankSessionState _s(ProviderContainer c) =>
    c.read(questionBankSessionProvider);

/// Reads the three indicators plus the current 1-based question number.
List<int> _ind(ProviderContainer c) => [
  _s(c).remaining,
  _s(c).skippedCount,
  _s(c).score,
];

void main() {
  group('indicators', () {
    test('start: score 0, skipped 0, remaining 100', () {
      final e = _exam(100);
      expect(_ind(e.c), [100, 0, 0]);
    });

    test('correct, incorrect and skip follow the specified semantics', () {
      final e = _exam(100);
      e.n.answer(0); // Q1 correct
      expect(_ind(e.c), [99, 0, 1]);
      expect(e.n.advance(), isFalse);
      e.n.answer(1); // Q2 incorrect
      expect(_ind(e.c), [98, 0, 1]);
      e.n.advance();
      e.n.skip(); // Q3 skipped
      expect(_ind(e.c), [98, 1, 1]);
      expect(_s(e.c).currentIndex, 3); // moved on to Q4
    });

    test('skipping the same question again never double counts', () {
      final e = _exam(5);
      e.n.skip(); // Q1
      e.n.skip(); // Q2
      expect(_s(e.c).skippedCount, 2);
      // Finish first pass to reach review, then skip repeatedly.
      e.n.answer(0);
      e.n.advance();
      e.n.answer(0);
      e.n.advance();
      e.n.answer(0);
      e.n.advance(); // Q5 answered -> review
      expect(_s(e.c).inReview, isTrue);
      e.n.skip();
      e.n.skip();
      e.n.skip();
      expect(_s(e.c).skippedCount, 2);
      expect(_s(e.c).remaining, 2);
    });

    test('rapid repeated taps do not change state twice', () {
      final e = _exam(5);
      e.n.answer(0);
      e.n.answer(0);
      e.n.answer(1);
      expect(_ind(e.c), [4, 0, 1]);
      e.n.advance();
      e.n.advance(); // second tap: current unanswered -> ignored
      expect(_s(e.c).currentIndex, 1);
    });
  });

  group('skipped queue', () {
    test('first pass is not interrupted; review follows Q100 in order', () {
      final e = _exam(6);
      e.n.answer(0);
      e.n.advance(); // Q1
      e.n.skip(); // Q2 skipped
      expect(_s(e.c).currentIndex, 2, reason: 'continues to Q3, no jump back');
      e.n.answer(0);
      e.n.advance(); // Q3
      e.n.skip(); // Q4 skipped
      e.n.answer(0);
      e.n.advance(); // Q5
      expect(_s(e.c).inReview, isFalse);
      e.n.skip(); // Q6 skipped; end of first pass
      expect(_s(e.c).inReview, isTrue);
      expect(_s(e.c).currentIndex, 1, reason: 'review starts at Q2');
      expect(_ind(e.c), [3, 3, 3]);

      e.n.answer(0); // Q2 correct
      expect(_ind(e.c), [2, 2, 4]);
      expect(e.n.advance(), isFalse);
      expect(_s(e.c).currentIndex, 3, reason: 'original numbering: Q4');
      e.n.answer(1); // Q4 incorrect
      expect(_ind(e.c), [1, 1, 4]);
      e.n.advance();
      expect(_s(e.c).currentIndex, 5);
      e.n.answer(0);
      expect(_ind(e.c), [0, 0, 5]);
      expect(e.n.advance(), isTrue, reason: 'nothing left: complete');
    });

    test('Q100 answered with nothing skipped completes the exam', () {
      final e = _exam(3);
      for (var i = 0; i < 2; i++) {
        e.n.answer(0);
        e.n.advance();
      }
      e.n.answer(0);
      expect(e.n.advance(), isTrue);
      expect(_s(e.c).inReview, isFalse);
    });

    test('Q100 answered with skipped questions enters review', () {
      final e = _exam(3);
      e.n.skip(); // Q1
      e.n.answer(0);
      e.n.advance(); // Q2
      e.n.answer(0);
      expect(e.n.advance(), isFalse);
      expect(_s(e.c).inReview, isTrue);
      expect(_s(e.c).currentIndex, 0);
    });

    test('skipping in review cycles between skipped questions only', () {
      final e = _exam(4);
      e.n.skip(); // Q1
      e.n.answer(0);
      e.n.advance(); // Q2
      e.n.skip(); // Q3
      e.n.answer(0);
      e.n.advance(); // Q4 -> review at Q1
      expect(_s(e.c).currentIndex, 0);
      e.n.skip();
      expect(_s(e.c).currentIndex, 2);
      e.n.skip();
      expect(_s(e.c).currentIndex, 0);
      expect(_ind(e.c), [2, 2, 2]);
    });
  });

  group('completion', () {
    test(
      'timeout counts unanswered and skipped as incorrect out of 100',
      () async {
        final e = _exam(100);
        for (var i = 0; i < 72; i++) {
          e.n.answer(0);
          e.n.advance();
        }
        for (var i = 0; i < 5; i++) {
          e.n.skip();
        }
        expect(_ind(e.c), [28, 5, 72]);
        final done = await e.n.complete(); // timer reached 00:00
        expect(done.attempt.correctAnswers, 72);
        expect(done.attempt.totalQuestions, 100);
        expect(done.attempt.score, 72);
        expect(e.repo.saved, [72]);
      },
    );

    test('timeout and manual submit at once save a single attempt', () async {
      final e = _exam(10);
      e.n.answer(0);
      final results = await Future.wait([e.n.complete(), e.n.complete()]);
      expect(e.repo.saved, hasLength(1));
      expect(results.first.attempt.attemptType, 'subject_exam');
      // Closed: no further answers or skips change anything.
      e.n.advance();
      e.n.answer(0);
      e.n.skip();
      expect(_ind(e.c), [9, 0, 1]);
    });
  });

  group('exam screen', () {
    testWidgets('timer keeps running through skip, answer and review', (
      tester,
    ) async {
      final repo = _Repo();
      var now = DateTime.utc(2026, 1, 1, 13);
      final router = GoRouter(
        initialLocation: '/exam',
        routes: [
          GoRoute(
            path: '/exam',
            builder: (_, _) => QuestionBankPracticeScreen(
              selection: _selection,
              examQuestions: _qs(3),
            ),
          ),
          GoRoute(
            path: RouteConstants.questionBankResults,
            builder: (_, _) => const Scaffold(body: Text('Results')),
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
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('Skipped'), findsOneWidget);
      expect(find.text('Score'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);

      Future<void> minutes(int m) async {
        now = now.add(Duration(minutes: m));
        await tester.pump(const Duration(seconds: 1));
      }

      await tester.tap(find.text('SKIP')); // Q1 skipped
      await minutes(5);
      expect(find.text('55:00'), findsOneWidget);

      await tester.tap(find.text('Right 2'));
      await tester.pump();
      await tester.tap(find.text('NEXT'));
      await tester.pump();
      await tester.tap(find.text('Right 3'));
      await tester.pump();
      await minutes(5);
      expect(find.text('50:00'), findsOneWidget);
      await tester.tap(find.text('NEXT'));
      await tester.pump();
      // Q3 was last: first pass done, one skipped left -> review at Q1.
      expect(find.text('Reviewing skipped'), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
      await minutes(5);
      expect(find.text('45:00'), findsOneWidget);

      // Time expires with Q1 still unanswered: auto submit, 2 of 3 correct.
      await minutes(50);
      await tester.pumpAndSettle();
      expect(find.text('Results'), findsOneWidget);
      expect(repo.saved, [2]);
    });
  });
}
