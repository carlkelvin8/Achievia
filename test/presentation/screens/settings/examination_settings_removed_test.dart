import 'dart:math';

import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/question_bank_helpers.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/repository/questions/question_bank_repository.dart';
import 'package:achievia/presentation/provider/home/daily_motivation_provider.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_practice_screen.dart';
import 'package:achievia/presentation/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  ],
);

List<QuestionItemEntity> _questions(int n) => [
  for (var i = 1; i <= n; i++) _q(i),
];

class _FakeRepo implements QuestionBankRepository {
  _FakeRepo({this.examQuestions = const []});

  final List<QuestionItemEntity> examQuestions;
  int examLoads = 0;
  int? lastRequestedCount;
  final saved = <QuestionBankSelection>[];

  @override
  Future<List<QuestionItemEntity>> getSubjectExamQuestions(
    int subjectId, {
    int count = 100,
    Random? random,
  }) async {
    examLoads++;
    lastRequestedCount = count;
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

/// Seeds the legacy keys the removed Examination Settings screen used to
/// persist. Nothing may read them any more.
Future<void> _seedLegacyExamPrefs({int items = 25, int minutes = 180}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'number_of_items': items,
    'duration_minutes': minutes,
    'is_default': false,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings no longer offers Examination Settings', () {
    testWidgets('settings screen omits the Examination entry', (tester) async {
      final router = GoRouter(
        initialLocation: RouteConstants.settings,
        routes: [
          GoRoute(
            path: RouteConstants.settings,
            builder: (_, _) => const SettingsScreen(),
          ),
          GoRoute(
            path: RouteConstants.pomodoroTimer,
            builder: (_, _) => const Scaffold(body: Text('Pomodoro')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [isAdminProvider.overrideWith((ref) async => false)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Examination'), findsNothing);
      // Unrelated settings entries are preserved.
      expect(find.text('Pomodoro Timer'), findsOneWidget);
    });
  });

  group('Take an Exam uses a fixed configuration', () {
    test('constants are 100 questions and 60 minutes', () {
      expect(subjectExamQuestionCount, 100);
      expect(subjectExamDuration, const Duration(minutes: 60));
    });

    testWidgets('exam is requested with 100 questions and no override', (
      tester,
    ) async {
      await _seedLegacyExamPrefs(items: 25, minutes: 180);
      final repo = _FakeRepo(examQuestions: _questions(100));
      final router = GoRouter(
        initialLocation: '/exam',
        routes: [
          GoRoute(
            path: '/exam',
            builder: (_, _) => QuestionBankPracticeScreen(
              selection: const QuestionBankSelection(subject: _subject),
              examQuestions: repo.examQuestions,
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
          overrides: [questionBankRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // The session holds exactly the fixed 100 questions.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(QuestionBankPracticeScreen)),
      );
      expect(
        container.read(questionBankSessionProvider).questions,
        hasLength(100),
      );
      // The deadline is the fixed 60 minutes from now.
      final endsAt = container.read(questionBankSessionProvider).endsAt!;
      final remaining = endsAt.difference(DateTime.now());
      expect(remaining.inMinutes, 59);
      expect(remaining.inMinutes, lessThanOrEqualTo(60));
    });

    test('the repository contract defaults to 100 questions', () {
      final repo = _FakeRepo(examQuestions: _questions(100));
      return repo.getSubjectExamQuestions(1).then((_) {
        expect(repo.lastRequestedCount, 100);
      });
    });
  });

  group('Stored Examination Settings are ignored', () {
    test('legacy question count and duration do not affect a new exam', () {
      // No code reads these keys any more, so seeding them cannot change
      // the fixed configuration.
      expect(subjectExamQuestionCount, isNot(25));
      expect(subjectExamDuration.inMinutes, isNot(180));
    });

    testWidgets('exam still shows 60:00 with hostile stored values', (
      tester,
    ) async {
      await _seedLegacyExamPrefs(items: 25, minutes: 5);
      final repo = _FakeRepo();
      var now = DateTime.utc(2026, 1, 1, 13);
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

      // Not the 5 minutes that was stored.
      expect(find.text('60:00'), findsOneWidget);
    });
  });

  group('Pomodoro study settings are unaffected', () {
    test('focus and break durations remain independently configurable', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(pomodoroSettingsProvider.notifier);

      expect(
        container.read(pomodoroSettingsProvider).focusDuration,
        const Duration(minutes: 25),
      );
      notifier.setFocusMinutes(45);
      notifier.setShortBreakMinutes(9);
      notifier.setLongBreakMinutes(50);

      final settings = container.read(pomodoroSettingsProvider);
      expect(settings.focusDuration, const Duration(minutes: 45));
      expect(settings.shortBreakDuration, const Duration(minutes: 9));
      expect(settings.longBreakDuration, const Duration(minutes: 50));
    });

    testWidgets('Pomodoro settings tile is still reachable from Settings', (
      tester,
    ) async {
      var pushed = 0;
      final router = GoRouter(
        initialLocation: RouteConstants.settings,
        routes: [
          GoRoute(
            path: RouteConstants.settings,
            builder: (_, _) => const SettingsScreen(),
          ),
          GoRoute(
            path: RouteConstants.pomodoroTimer,
            builder: (_, _) {
              pushed++;
              return const Scaffold(body: Text('Pomodoro'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [isAdminProvider.overrideWith((ref) async => false)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pomodoro Timer'));
      await tester.pumpAndSettle();
      expect(pushed, 1);
    });
  });
}
