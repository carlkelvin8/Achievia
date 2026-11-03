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

const _warning =
    'Are you sure you want to leave the exam?\n\n'
    'Your current progress will not be saved, and a new set of questions '
    'will be generated next time.';

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

List<QuestionItemEntity> _qs(int from, int count) => [
  for (var i = from; i < from + count; i++) _q(i),
];

class _Repo implements QuestionBankRepository {
  _Repo({required this.examSets});

  final List<List<QuestionItemEntity>> examSets;
  final savedAttempts = <QuestionBankAttempt>[];
  int examLoads = 0;

  @override
  Future<List<QuestionItemEntity>> getSubjectExamQuestions(
    int subjectId, {
    int count = 100,
    Random? random,
  }) async {
    final set = examSets.length == 1
        ? examSets.first
        : examSets[examLoads.clamp(0, examSets.length - 1)];
    examLoads++;
    return set;
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
    final attempt = QuestionBankAttempt(
      id: 'a${savedAttempts.length + 1}',
      userId: 'u',
      subjectId: selection.subject.id,
      subjectTitle: selection.subject.title,
      topicTitle: 'Subject Exam',
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      score: questionBankScore(correct: correctAnswers, total: totalQuestions),
      completedAt: DateTime.utc(2026, 1, 1),
      attemptType: selection.attemptType,
    );
    savedAttempts.add(attempt);
    return attempt;
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
  Future<List<QuestionBankAttempt>> getRecentAttempts({
    int limit = 5,
    String? attemptType,
  }) async => const [];
}

/// Home screen that mirrors `_startExam` on the topics screen: it pulls a
/// fresh random set from the repository and pushes the practice route.
class _Home extends ConsumerStatefulWidget {
  const _Home({required this.repo, required this.onExamLoaded});

  final _Repo repo;
  final void Function(int questionId) onExamLoaded;

  @override
  ConsumerState<_Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<_Home> {
  bool _starting = false;

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final questions = await ref
          .read(questionBankRepositoryProvider)
          .getSubjectExamQuestions(_subject.id);
      if (!mounted) return;
      widget.onExamLoaded(questions.first.id);
      await context.push(
        RouteConstants.questionBankPractice,
        extra: QuestionBankPracticeArgs(_selection, examQuestions: questions),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _start,
          child: const Text('Start Exam'),
        ),
      ),
    );
  }
}

class _Harness {
  _Harness({required this.repo, required this.examIds});

  final _Repo repo;
  final List<int> examIds;
}

Future<_Harness> _pumpExam(
  WidgetTester tester, {
  List<List<QuestionItemEntity>>? examSets,
}) async {
  final repo = _Repo(examSets: examSets ?? [_qs(1, 3)]);
  final examIds = <int>[];
  final now = ValueNotifier<DateTime>(DateTime.utc(2026, 1, 1, 13));
  addTearDown(now.dispose);

  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) =>
            _Home(repo: repo, onExamLoaded: (id) => examIds.add(id)),
      ),
      GoRoute(
        path: RouteConstants.questionBankPractice,
        builder: (_, state) {
          final args = state.extra as QuestionBankPracticeArgs;
          return QuestionBankPracticeScreen(
            selection: args.selection,
            examQuestions: args.examQuestions,
          );
        },
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
        questionBankClockProvider.overrideWithValue(() => now.value),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(repo: repo, examIds: examIds);
}

final _leaveButton = find.widgetWithText(TextButton, 'Leave Exam');

final _examQuestions = _qs(101, 3);

Future<void> _enterExam(WidgetTester tester) async {
  await tester.tap(find.text('Start Exam'));
  await tester.pumpAndSettle();
  expect(find.text('1 / 3'), findsOneWidget);
}

void main() {
  group('leave exam confirmation', () {
    testWidgets('back during an unfinished exam shows the exact warning', (
      tester,
    ) async {
      await _pumpExam(tester);
      await _enterExam(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text(_warning), findsOneWidget);
      expect(find.text('Stay'), findsWidgets);
      expect(_leaveButton, findsOneWidget);
    });

    testWidgets('tapping outside the dialog does not dismiss it', (
      tester,
    ) async {
      await _pumpExam(tester);
      await _enterExam(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(600, 100));
      await tester.pumpAndSettle();

      expect(find.text(_warning), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('tapping Stay keeps the exam and the dialog closes', (
      tester,
    ) async {
      await _pumpExam(tester);
      await _enterExam(tester);
      await tester.tap(find.text('Right 1')); // Q1 correct
      await tester.pump();
      await tester.tap(find.text('NEXT'));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();

      expect(find.text(_warning), findsNothing);
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text('Score'), findsOneWidget);
    });

    testWidgets('Leave Exam exits to the previous route without saving', (
      tester,
    ) async {
      final h = await _pumpExam(tester);
      await _enterExam(tester);
      await tester.tap(find.text('Right 1'));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(_leaveButton);
      await tester.pumpAndSettle();

      expect(find.text('Start Exam'), findsOneWidget);
      expect(find.text(_warning), findsNothing);
      expect(find.text('1 / 3'), findsNothing);
      expect(
        h.repo.savedAttempts,
        isEmpty,
        reason: 'an abandoned exam is never saved',
      );
    });

    testWidgets('rapid Leave Exam taps do not pop multiple routes', (
      tester,
    ) async {
      await _pumpExam(tester);
      await _enterExam(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(_leaveButton);
      await tester.tap(_leaveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Start Exam'), findsOneWidget);
      expect(find.text('1 / 3'), findsNothing);
    });

    testWidgets('timeout while the dialog is open finalizes exactly once', (
      tester,
    ) async {
      final repo = _Repo(examSets: [_qs(1, 3)]);
      final now = ValueNotifier<DateTime>(DateTime.utc(2026, 1, 1, 13));
      addTearDown(now.dispose);
      final router = GoRouter(
        initialLocation: '/exam',
        routes: [
          GoRoute(
            path: '/exam',
            builder: (_, _) => QuestionBankPracticeScreen(
              selection: _selection,
              examQuestions: _examQuestions,
            ),
          ),
          GoRoute(
            path: RouteConstants.questionBankResults,
            builder: (_, state) {
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
            questionBankClockProvider.overrideWithValue(() => now.value),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('60:00'), findsOneWidget);

      // Open the leave dialog, then time expires while it is open.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text(_warning), findsOneWidget);

      now.value = now.value.add(const Duration(minutes: 61));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Results'), findsOneWidget);
      expect(find.text(_warning), findsNothing);
      expect(repo.savedAttempts, hasLength(1));
    });

    testWidgets('start a new attempt generates a fresh exam question set', (
      tester,
    ) async {
      final h = await _pumpExam(tester, examSets: [_qs(1, 3), _qs(201, 3)]);
      await _enterExam(tester);
      expect(find.text('Right 1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(_leaveButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Exam'));
      await tester.pumpAndSettle();

      expect(h.repo.examLoads, 2);
      expect(h.examIds, [1, 201]);
      expect(find.text('Right 201'), findsOneWidget);
      expect(find.text('Right 1'), findsNothing);
      // Fresh session starts at question 1 of the new set.
      expect(find.text('1 / 3'), findsOneWidget);
    });
  });
}
