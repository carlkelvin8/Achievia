import 'dart:math';

import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart';
import 'package:achievia/core/utils/helpers.dart' show gradingBrackets;
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/repository/questions/question_bank_repository.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('result shows score and save confirmation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: QuestionBankResultScreen(
            args: QuestionBankResultArgs(
              selection: _selection,
              attempt: _savedAttempt,
              isSaved: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Result saved'), findsOneWidget);
  });

  testWidgets('shows the Achievia logo, square and centered, no trophy', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: QuestionBankResultScreen(
            args: QuestionBankResultArgs(
              selection: _selection,
              attempt: _savedAttempt,
              isSaved: true,
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.emoji_events_outlined), findsNothing);
    final logo = find.byKey(const ValueKey('result-logo'));
    expect(tester.getSize(logo), const Size(96, 96));
    expect(
      tester.getCenter(logo).dx,
      closeTo(tester.getSize(find.byType(Scaffold)).width / 2, 0.5),
    );
  });

  testWidgets('unsaved result can retry its Supabase write', (tester) async {
    final repository = _FakeQuestionBankRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          questionBankRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: QuestionBankResultScreen(
            args: QuestionBankResultArgs(
              selection: _selection,
              attempt: _unsavedAttempt,
              isSaved: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Result not saved'), findsOneWidget);
    await tester.tap(find.text('RETRY SAVE'));
    await tester.pumpAndSettle();

    expect(repository.saveCount, 1);
    expect(find.text('Result saved'), findsOneWidget);
  });

  group('subject exam status', () {
    const examSelection = QuestionBankSelection(subject: _subject);

    testWidgets('shows FAILED below the passing boundary', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuestionBankResultScreen(
              args: QuestionBankResultArgs(
                selection: examSelection,
                attempt: _subjectExamAttempt(score: 74),
                isSaved: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('FAILED'), findsOneWidget);
      expect(find.text('PASSED'), findsNothing);
      expect(find.text('74%'), findsOneWidget);
    });

    testWidgets('passes exactly at the shared 75% boundary', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuestionBankResultScreen(
              args: QuestionBankResultArgs(
                selection: examSelection,
                attempt: _subjectExamAttempt(score: 75),
                isSaved: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('PASSED'), findsOneWidget);
      expect(find.text('FAILED'), findsNothing);
    });

    testWidgets('passes a perfect score', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuestionBankResultScreen(
              args: QuestionBankResultArgs(
                selection: examSelection,
                attempt: _subjectExamAttempt(score: 100),
                isSaved: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('PASSED'), findsOneWidget);
      expect(find.text('FAILED'), findsNothing);
    });

    testWidgets('practice results never show a status chip', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuestionBankResultScreen(
              args: QuestionBankResultArgs(
                selection: _selection,
                attempt: _unsavedAttempt,
                isSaved: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('PASSED'), findsNothing);
      expect(find.text('FAILED'), findsNothing);
      expect(find.text(gradingBrackets[2].message), findsNothing);
    });
  });

  group('grading interpretation', () {
    const examSelection = QuestionBankSelection(subject: _subject);

    testWidgets('failed 72% shows remark and interpretation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuestionBankResultScreen(
              args: QuestionBankResultArgs(
                selection: examSelection,
                attempt: _subjectExamAttempt(score: 72),
                isSaved: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('FAILED'), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('72 / 100'), findsOneWidget);
      expect(find.text(gradingBrackets[2].level), findsOneWidget);
      expect(find.text(gradingBrackets[2].message), findsOneWidget);
    });

    testWidgets('passed 80% shows its own remark and interpretation', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuestionBankResultScreen(
              args: QuestionBankResultArgs(
                selection: examSelection,
                attempt: _subjectExamAttempt(score: 80),
                isSaved: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('PASSED'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text(gradingBrackets[3].level), findsOneWidget);
      expect(find.text(gradingBrackets[3].message), findsOneWidget);
      expect(find.text(gradingBrackets[2].message), findsNothing);
    });

    testWidgets('timed-out exam grades unanswered questions out of 100', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuestionBankResultScreen(
              args: QuestionBankResultArgs(
                selection: examSelection,
                attempt: _subjectExamAttempt(score: 72),
                isSaved: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('72 / 100'), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('FAILED'), findsOneWidget);
      expect(find.text(gradingBrackets[2].level), findsOneWidget);
    });

    testWidgets('grading interpretation survives a narrow screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: QuestionBankResultScreen(
              args: QuestionBankResultArgs(
                selection: examSelection,
                attempt: _subjectExamAttempt(score: 92),
                isSaved: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text(gradingBrackets[5].level), findsOneWidget);
      expect(find.text(gradingBrackets[5].message), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('long interpretation wraps under large text scaling', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: QuestionBankResultScreen(
              args: QuestionBankResultArgs(
                selection: examSelection,
                attempt: _subjectExamAttempt(score: 92),
                isSaved: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text(gradingBrackets[5].level), findsOneWidget);
      expect(find.text(gradingBrackets[5].message), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('grading persists while waiting to retry the save', (
      tester,
    ) async {
      final repository = _FakeQuestionBankRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            questionBankRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: QuestionBankResultScreen(
              args: QuestionBankResultArgs(
                selection: examSelection,
                attempt: _subjectExamAttempt(score: 72),
                isSaved: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Result not saved'), findsOneWidget);
      expect(find.text('RETRY SAVE'), findsOneWidget);
      expect(find.text('FAILED'), findsOneWidget);
      expect(find.text(gradingBrackets[2].message), findsOneWidget);

      await tester.ensureVisible(find.text('RETRY SAVE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('RETRY SAVE'));
      await tester.pumpAndSettle();

      expect(repository.saveCount, 1);
      expect(find.text('Result saved'), findsOneWidget);
      expect(find.text(gradingBrackets[1].level), findsOneWidget);
    });
  });
}

const _subject = QuestionBankSubject(
  id: 1,
  courseId: 4,
  title: 'Clinical Chemistry',
  description: '',
  image: '',
);
const _topic = QuestionBankTopic(
  id: 8,
  subjectId: 1,
  title: 'Enzymes',
  description: '',
);
const _selection = QuestionBankSelection(subject: _subject, topic: _topic);
final _savedAttempt = QuestionBankAttempt(
  id: 'attempt-1',
  userId: 'user-1',
  subjectId: 1,
  topicId: 8,
  subjectTitle: 'Clinical Chemistry',
  topicTitle: 'Enzymes',
  correctAnswers: 1,
  totalQuestions: 2,
  score: 50,
  completedAt: DateTime.utc(2026, 8, 14),
);
final _unsavedAttempt = QuestionBankAttempt(
  id: '',
  userId: '',
  subjectId: 1,
  topicId: 8,
  subjectTitle: 'Clinical Chemistry',
  topicTitle: 'Enzymes',
  correctAnswers: 1,
  totalQuestions: 2,
  score: 50,
  completedAt: DateTime.utc(2026, 8, 14),
);

QuestionBankAttempt _subjectExamAttempt({required double score}) =>
    QuestionBankAttempt(
      id: 'subject-exam-1',
      userId: 'user-1',
      subjectId: 1,
      subjectTitle: 'Clinical Chemistry',
      topicTitle: '',
      correctAnswers: score.round(),
      totalQuestions: 100,
      score: score,
      completedAt: DateTime.utc(2026, 8, 14),
      attemptType: QuestionBankAttempt.subjectExamType,
    );

class _FakeQuestionBankRepository implements QuestionBankRepository {
  int saveCount = 0;

  @override
  Future<List<QuestionBankSubject>> getAllSubjects() async => const [];

  @override
  Future<List<QuestionItemEntity>> getSubjectExamQuestions(
    int subjectId, {
    int count = 100,
    Random? random,
  }) async => const [];

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
    saveCount += 1;
    return _savedAttempt;
  }

  @override
  Future<List<QuestionBankAttempt>> getRecentAttempts({
    int limit = 5,
    String? attemptType,
  }) async => const [];

  @override
  Future<List<QuestionItemEntity>> getPracticeQuestions(
    int quizId, {
    int limit = 20,
    Random? random,
  }) async => const [];

  @override
  Future<List<QuestionBankSubject>> getSubjectsForCourse(int courseId) async =>
      const [];

  @override
  Future<List<QuestionBankTopic>> getTopics(int subjectId) async => const [];
}
