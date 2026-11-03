import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/recent_results.dart';
import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/widgets/examination_results_entity.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:achievia/presentation/provider/profile/profile_view_state.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/screens/question_bank/exam_summary_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/profile_screen_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'question_bank/exam_summary_test.dart'
    show FakeRepo, snapshotOf, testUser;

const _profile = ProfileScreenViewData(
  card: ProfileCardViewData(
    lastName: 'DOE',
    firstName: 'JANE',
    middleName: 'A',
    university: 'UNI',
    purpose: 'MTLE',
    dateOfExam: 'N/A',
    profileImageUrl: '',
  ),
  boardExamDate: null,
  boardExamDateLabel: 'N/A',
  daysLeftLabel: 'N/A',
  mantraText: 'Keep going',
);

QuestionBankAttempt subjectAttempt(
  String id, {
  required DateTime at,
  double score = 80,
  bool hasSummary = true,
  String subjectTitle = 'Clinical Chemistry',
}) => QuestionBankAttempt(
  id: id,
  userId: 'user-a',
  subjectId: 1,
  subjectTitle: subjectTitle,
  topicTitle: 'Subject Exam',
  correctAnswers: score.round(),
  totalQuestions: 100,
  score: score,
  completedAt: at,
  attemptType: QuestionBankAttempt.subjectExamType,
  hasSummary: hasSummary,
);

final base = DateTime.utc(2026, 10, 5, 12);

Future<GoRouter> pumpProfile(
  WidgetTester t, {
  List<QuestionBankAttempt>? attempts,
  List<ExaminationResult> mockBoards = const [],
  FakeRepo? repo,
}) async {
  t.view.physicalSize = const Size(600, 3000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ProfileScreenContent()),
      GoRoute(
        path: RouteConstants.questionBankExamSummary,
        builder: (_, state) {
          final args = examSummaryArgsFromRoute(
            extra: state.extra,
            query: state.uri.queryParameters,
          );
          return ExamSummaryScreen(args: args!);
        },
      ),
    ],
  );
  await t.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        profileScreenViewProvider.overrideWithValue(const AsyncData(_profile)),
        // null = use the real provider against the fake repository.
        if (attempts != null)
          recentSubjectExamAttemptsProvider.overrideWith(
            (ref) async => attempts,
          ),
        recentMockBoardResultsProvider.overrideWith((ref) async => mockBoards),
        questionBankRepositoryProvider.overrideWithValue(repo ?? FakeRepo()),
        activeAccountIdProvider.overrideWith(
          (ref) => Stream.value(ref.watch(testUser)),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await settle(t);
  return router;
}

/// Settles the tree, then discards the one expected failure: the real Profile
/// card fetches a placeholder network image and tests have no network.
Future<void> settle(WidgetTester t) async {
  await t.pumpAndSettle();
  Object? error;
  while ((error = t.takeException()) != null) {
    if (error is! NetworkImageLoadException) throw error!;
  }
}

Finder get resultTaps => find.byKey(const ValueKey('recent-result-tap'));

void main() {
  group('recent results list', () {
    testWidgets('shows the latest 10 exams, newest first', (t) async {
      final attempts = [
        for (var i = 0; i < 12; i++)
          subjectAttempt(
            'id-$i',
            at: base.subtract(Duration(days: i)),
            score: 60.0 + i,
            subjectTitle: 'Subject $i',
          ),
      ];
      await pumpProfile(t, attempts: attempts);
      for (var i = 0; i < 10; i++) {
        expect(find.text('Subject $i'), findsOneWidget);
      }
      expect(find.text('Subject 10'), findsNothing);
      expect(find.text('Subject 11'), findsNothing);
      expect(resultTaps, findsNWidgets(10));
    });

    testWidgets('a newer 11th result pushes out the oldest', (t) async {
      final attempts = [
        subjectAttempt('n', at: base, subjectTitle: 'Newest'),
        for (var i = 1; i < 10; i++)
          subjectAttempt(
            'm$i',
            at: base.subtract(Duration(days: i)),
            subjectTitle: 'Middle $i',
          ),
        subjectAttempt(
          'd',
          at: base.subtract(const Duration(days: 10)),
          subjectTitle: 'Oldest',
        ),
      ];
      await pumpProfile(t, attempts: attempts);
      expect(find.text('Newest'), findsOneWidget);
      expect(find.text('Middle 9'), findsOneWidget);
      expect(find.text('Oldest'), findsNothing);
      expect(resultTaps, findsNWidgets(10));
    });

    testWidgets('practice attempts cannot crowd an older exam out of the '
        'latest 3', (t) async {
      final repo = FakeRepo();
      QuestionBankAttempt practice(int daysAgo) => QuestionBankAttempt(
        id: 'practice-$daysAgo',
        userId: 'user-a',
        subjectId: 1,
        subjectTitle: 'Practice Subject',
        topicTitle: 'Topic',
        correctAnswers: 10,
        totalQuestions: 20,
        score: 50,
        completedAt: base.subtract(Duration(days: daysAgo)),
      );
      // Newest 5 attempts are all practice; the exam is older than them.
      repo.recentAttempts.addAll([
        for (var i = 0; i < 5; i++) practice(i),
        subjectAttempt(
          'old-exam',
          at: base.subtract(const Duration(days: 30)),
          subjectTitle: 'Older Exam Subject',
        ),
      ]);
      await pumpProfile(t, repo: repo, attempts: null);

      // The type filter reaches the data source together with the limit.
      expect(repo.recentQueries, [
        (
          limit: examHistoryLimit,
          attemptType: QuestionBankAttempt.subjectExamType,
        ),
      ]);
      expect(find.text('Older Exam Subject'), findsOneWidget);
      expect(find.text('Practice Subject'), findsNothing);
      expect(resultTaps, findsOneWidget);
    });

    testWidgets('the latest 3 exams plus every Mock Board are listed', (
      t,
    ) async {
      final repo = FakeRepo();
      repo.recentAttempts.addAll([
        subjectAttempt('e1', at: base, subjectTitle: 'Exam One'),
        subjectAttempt(
          'e2',
          at: base.subtract(const Duration(days: 2)),
          subjectTitle: 'Exam Two',
        ),
        subjectAttempt(
          'e3',
          at: base.subtract(const Duration(days: 4)),
          subjectTitle: 'Exam Three',
        ),
      ]);
      await pumpProfile(
        t,
        repo: repo,
        attempts: null,
        mockBoards: [
          ExaminationResult(
            examName: 'Mock Board Newer',
            date: base.subtract(const Duration(days: 1)).toIso8601String(),
            score: 90,
            passingScore: 75,
          ),
        ],
      );
      // Newest first; the Mock Board never pushes out or is pushed out.
      expect(find.text('Exam One'), findsOneWidget);
      expect(find.text('Mock Board Newer'), findsOneWidget);
      expect(find.text('Exam Two'), findsOneWidget);
      expect(find.text('Exam Three'), findsOneWidget);
    });

    testWidgets('empty state is unchanged and has nothing tappable', (t) async {
      await pumpProfile(t, attempts: const []);
      expect(find.text('No results found.'), findsOneWidget);
      expect(resultTaps, findsNothing);
    });

    testWidgets('opening Profile never loads any summary', (t) async {
      final repo = FakeRepo();
      await pumpProfile(
        t,
        repo: repo,
        attempts: [
          for (var i = 0; i < 3; i++)
            subjectAttempt('id-$i', at: base.subtract(Duration(days: i))),
        ],
      );
      expect(repo.summaryLoads, 0);
      expect(repo.liveQuestionCalls, 0);
    });

    testWidgets('Mock Board results stay visible and are not tappable', (
      t,
    ) async {
      await pumpProfile(
        t,
        attempts: const [],
        mockBoards: [
          ExaminationResult(
            examName: 'Mock Board 1',
            date: base.toIso8601String(),
            score: 82,
            passingScore: 75,
          ),
        ],
      );
      expect(find.text('Mock Board 1'), findsOneWidget);
      expect(resultTaps, findsNothing);
      await t.tap(find.text('Mock Board 1'));
      await settle(t);
      expect(find.byType(ExamSummaryScreen), findsNothing);
    });

    testWidgets('a mixed list keeps Mock Board untouched next to exams', (
      t,
    ) async {
      await pumpProfile(
        t,
        attempts: [subjectAttempt('exam-1', at: base)],
        mockBoards: [
          ExaminationResult(
            examName: 'Mock Board 2',
            date: base.subtract(const Duration(days: 1)).toIso8601String(),
            score: 70,
            passingScore: 75,
          ),
        ],
      );
      expect(find.text('Clinical Chemistry'), findsOneWidget);
      expect(find.text('Mock Board 2'), findsOneWidget);
      expect(resultTaps, findsOneWidget); // only the subject exam
    });
  });

  group('reopening a subject exam', () {
    testWidgets('opens the exact attempt by id; back returns to Profile', (
      t,
    ) async {
      final repo = FakeRepo();
      final snap = snapshotOf(4, 3, base: 700);
      repo.byUser['user-a'] = {
        'attempt-77': snap.toSummary(attemptId: 'attempt-77'),
      };
      final router = await pumpProfile(
        t,
        repo: repo,
        attempts: [subjectAttempt('attempt-77', at: base)],
      );

      await t.tap(resultTaps);
      await settle(t);
      expect(find.text('Exam Summary'), findsOneWidget);
      expect(find.text('Question text 700'), findsOneWidget);
      expect(find.text('Question 1 of 4'), findsOneWidget);
      expect(repo.summaryLoads, 1);
      expect(find.byKey(const ValueKey('summary-not-saved')), findsNothing);
      // Read-only reopen: nothing is generated or saved.
      expect(repo.liveQuestionCalls, 0);
      expect(repo.saves, isEmpty);
      // Strictly read-only: no exam controls, no answer widgets.
      for (final text in ['Skip', 'Next', 'Submit', 'View Result']) {
        expect(find.text(text), findsNothing);
      }
      expect(find.byType(RadioListTile<int>), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);

      router.pop();
      await settle(t);
      expect(find.text('Recent Results:'), findsOneWidget);
      expect(find.byType(ExamSummaryScreen), findsNothing);
    });

    testWidgets('two attempts with the same subject and score open their own '
        'summaries', (t) async {
      final repo = FakeRepo();
      repo.byUser['user-a'] = {
        'attempt-a': snapshotOf(
          3,
          3,
          base: 100,
        ).toSummary(attemptId: 'attempt-a'),
        'attempt-b': snapshotOf(
          3,
          3,
          base: 900,
        ).toSummary(attemptId: 'attempt-b'),
      };
      final router = await pumpProfile(
        t,
        repo: repo,
        attempts: [
          subjectAttempt('attempt-a', at: base, score: 88),
          subjectAttempt(
            'attempt-b',
            at: base.subtract(const Duration(days: 1)),
            score: 88,
          ),
        ],
      );
      expect(resultTaps, findsNWidgets(2));

      await t.tap(resultTaps.at(0));
      await settle(t);
      expect(find.text('Question text 100'), findsOneWidget);
      expect(find.text('Question text 900'), findsNothing);
      router.pop();
      await settle(t);

      await t.tap(resultTaps.at(1));
      await settle(t);
      expect(find.text('Question text 900'), findsOneWidget);
      expect(find.text('Question text 100'), findsNothing);
    });

    testWidgets('shows the stored snapshot, not current Question Bank text', (
      t,
    ) async {
      final repo = FakeRepo();
      // The persisted snapshot says "Old wording"; whatever the live bank says
      // now is irrelevant because it is never consulted.
      final old = snapshotOf(1, 1, base: 300);
      final summary = ExamAttemptSummary(
        attemptId: 'attempt-1',
        items: [
          ExamSummaryItem(
            position: 1,
            questionId: null, // live question was deleted
            questionText: 'Old wording of the question',
            choices: old.items.first.choices,
            selectedIndex: old.items.first.selectedIndex,
            correctIndex: old.items.first.correctIndex,
          ),
        ],
      );
      repo.byUser['user-a'] = {'attempt-1': summary};
      await pumpProfile(
        t,
        repo: repo,
        attempts: [subjectAttempt('attempt-1', at: base)],
      );
      await t.tap(resultTaps);
      await settle(t);
      expect(find.text('Old wording of the question'), findsOneWidget);
      expect(repo.liveQuestionCalls, 0);
    });

    testWidgets('legacy attempt: card stays, summary is unavailable, nothing '
        'is faked', (t) async {
      final repo = FakeRepo()
        ..failWith = const ExamSummaryException(ExamSummaryFailure.unavailable);
      final router = await pumpProfile(
        t,
        repo: repo,
        attempts: [subjectAttempt('old-1', at: base, hasSummary: false)],
      );
      expect(find.text('Clinical Chemistry'), findsOneWidget);
      expect(find.text('Score: 80.0%'), findsOneWidget);

      await t.tap(resultTaps);
      await settle(t);
      expect(
        find.text(
          'Detailed summary is unavailable for this older exam result.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('summary-list')), findsNothing);
      expect(find.textContaining('Question text'), findsNothing);
      expect(repo.liveQuestionCalls, 0);
      expect(find.byKey(const ValueKey('summary-retry')), findsOneWidget);

      router.pop();
      await settle(t);
      expect(find.text('Clinical Chemistry'), findsOneWidget);
      expect(find.text('Score: 80.0%'), findsOneWidget);
    });

    testWidgets('a deleted attempt shows a safe not-found state', (t) async {
      final repo = FakeRepo(); // knows no attempts at all
      await pumpProfile(
        t,
        repo: repo,
        attempts: [subjectAttempt('gone-1', at: base)],
      );
      await t.tap(resultTaps);
      await settle(t);
      expect(
        find.text('This exam attempt could not be found.'),
        findsOneWidget,
      );
      expect(find.textContaining('Question text'), findsNothing);
    });

    testWidgets(
      'malformed, denied and network failures are distinct and safe',
      (t) async {
        for (final (error, text) in [
          (
            const ExamSummaryException(ExamSummaryFailure.malformed),
            'inconsistent',
          ),
          (
            const ExamSummaryException(ExamSummaryFailure.denied),
            'do not have access',
          ),
          (Exception('SocketException: secret host'), 'Unable to load'),
        ]) {
          final repo = FakeRepo()..failWith = error;
          await pumpProfile(
            t,
            repo: repo,
            attempts: [subjectAttempt('x-1', at: base)],
          );
          await t.tap(resultTaps);
          await settle(t);
          expect(find.textContaining(text), findsOneWidget);
          // Raw exception text is never shown.
          expect(find.textContaining('secret host'), findsNothing);
          expect(find.textContaining('Exception'), findsNothing);
          // A permanent failure must not leave a spinner behind.
          expect(find.byKey(const ValueKey('summary-loading')), findsNothing);
        }
      },
    );

    testWidgets('a rapid double tap opens one summary and loads once', (
      t,
    ) async {
      final repo = FakeRepo();
      repo.byUser['user-a'] = {
        'attempt-1': snapshotOf(3, 3).toSummary(attemptId: 'attempt-1'),
      };
      await pumpProfile(
        t,
        repo: repo,
        attempts: [subjectAttempt('attempt-1', at: base)],
      );
      await t.tap(resultTaps);
      await t.tap(resultTaps, warnIfMissed: false);
      await settle(t);
      expect(find.byType(ExamSummaryScreen), findsOneWidget);
      expect(repo.summaryLoads, 1);
    });
  });

  group('account isolation', () {
    testWidgets("user B cannot open user A's attempt", (t) async {
      final repo = FakeRepo();
      repo.byUser['user-a'] = {
        'attempt-a': snapshotOf(3, 3).toSummary(attemptId: 'attempt-a'),
      };
      repo.user = 'user-b';
      await pumpProfile(
        t,
        repo: repo,
        attempts: [subjectAttempt('attempt-a', at: base)],
      );
      // user-b is signed in but navigates with user-a's id.
      ProviderScope.containerOf(
        t.element(find.byType(ProfileScreenContent)),
      ).read(testUser.notifier).state = 'user-b';
      await t.pump();
      await t.tap(resultTaps);
      await settle(t);
      expect(
        find.text('This exam attempt could not be found.'),
        findsOneWidget,
      );
      expect(find.textContaining('Question text'), findsNothing);
    });

    testWidgets('switching account while a summary is open drops it', (
      t,
    ) async {
      final repo = FakeRepo();
      repo.byUser['user-a'] = {
        'attempt-a': snapshotOf(3, 3).toSummary(attemptId: 'attempt-a'),
      };
      await pumpProfile(
        t,
        repo: repo,
        attempts: [subjectAttempt('attempt-a', at: base)],
      );
      await t.tap(resultTaps);
      await settle(t);
      expect(find.text('Question 1 of 3'), findsOneWidget);

      repo.user = 'user-b';
      ProviderScope.containerOf(
        t.element(find.byType(ExamSummaryScreen)),
      ).read(testUser.notifier).state = 'user-b';
      await settle(t);
      expect(find.text('Question 1 of 3'), findsNothing);
      expect(find.byKey(const ValueKey('summary-error')), findsOneWidget);

      // Back to user A: their own attempt loads normally again.
      repo.user = 'user-a';
      ProviderScope.containerOf(
        t.element(find.byType(ExamSummaryScreen)),
      ).read(testUser.notifier).state = 'user-a';
      await settle(t);
      expect(find.text('Question 1 of 3'), findsOneWidget);
    });
  });

  group('the summary route on its own', () {
    Future<void> openRoute(
      WidgetTester t,
      String location, {
      FakeRepo? repo,
    }) async {
      final router = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(
            path: RouteConstants.questionBankExamSummary,
            builder: (_, state) {
              final args = examSummaryArgsFromRoute(
                extra: state.extra,
                query: state.uri.queryParameters,
              );
              return args == null
                  ? const Scaffold(body: Text('missing route data'))
                  : ExamSummaryScreen(args: args);
            },
          ),
        ],
      );
      await t.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
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
      await settle(t);
    }

    testWidgets('opens a valid attempt from the id alone (deep link)', (
      t,
    ) async {
      final repo = FakeRepo();
      repo.byUser['user-a'] = {
        'attempt-9': snapshotOf(
          2,
          2,
          base: 400,
        ).toSummary(attemptId: 'attempt-9'),
      };
      await openRoute(
        t,
        '${RouteConstants.questionBankExamSummary}?attempt=attempt-9',
        repo: repo,
      );
      expect(find.text('Question text 400'), findsOneWidget);
    });

    testWidgets('no data, empty or malformed ids fail safely without a query', (
      t,
    ) async {
      final repo = FakeRepo();
      await openRoute(t, RouteConstants.questionBankExamSummary, repo: repo);
      expect(find.text('missing route data'), findsOneWidget);

      for (final bad in ['', 'bad%20id!', '..%2F..%2Fx']) {
        await openRoute(
          t,
          '${RouteConstants.questionBankExamSummary}?attempt=$bad',
          repo: repo,
        );
        expect(
          find.text('This exam result could not be opened.'),
          findsOneWidget,
        );
      }
      expect(repo.summaryLoads, 0);
    });

    test('args helper prefers extra and reads the query otherwise', () {
      const extra = ExamSummaryArgs(attemptId: 'from-extra');
      expect(
        examSummaryArgsFromRoute(extra: extra, query: {'attempt': 'q'}),
        same(extra),
      );
      expect(
        examSummaryArgsFromRoute(query: {'attempt': 'q1'})!.attemptId,
        'q1',
      );
      expect(examSummaryArgsFromRoute(query: {}), isNull);
      expect(isValidExamAttemptId('a-b_c1'), isTrue);
      for (final bad in [null, '', ' ', 'a b', 'a/b', 'x' * 65]) {
        expect(isValidExamAttemptId(bad), isFalse, reason: '$bad');
      }
    });
  });
}
