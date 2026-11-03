import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/data/data_source/reviewer/question_bank_remote_datasource.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_subjects_screen.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_topics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

QuestionBankSubject _subject(int id, String title) => QuestionBankSubject(
  id: id,
  courseId: 1,
  title: title,
  description: '',
  image: '',
);

QuestionBankTopic _topic(int id, int subjectId, String title) =>
    QuestionBankTopic(
      id: id,
      subjectId: subjectId,
      title: title,
      description: '',
    );

final _chem = _subject(1, 'Clinical Chemistry');
final _bact = _subject(2, 'Bacteriology');
final _hema = _subject(3, 'Hematology');

final _topicsBySubject = {
  1: [_topic(10, 1, 'Carbohydrates'), _topic(11, 1, 'Enzymes')],
  2: [_topic(20, 2, 'Gram Stain')],
};

StudyModeArgs? _practiceSelection;

Widget _app() {
  final router = GoRouter(
    initialLocation: '/subjects',
    routes: [
      GoRoute(
        path: '/subjects',
        builder: (_, _) => const QuestionBankSubjectsScreen(),
      ),
      GoRoute(
        path: RouteConstants.questionBankTopics,
        builder: (_, state) => QuestionBankTopicsScreen(
          subject: (state.extra as QuestionBankTopicArgs).subject,
        ),
      ),
      GoRoute(
        path: RouteConstants.questionBankStudy,
        builder: (_, state) {
          _practiceSelection = state.extra as StudyModeArgs;
          return const Scaffold(body: Text('Practice screen'));
        },
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      questionBankSubjectsProvider.overrideWith(
        (ref) async => [_chem, _bact, _hema],
      ),
      recentQuestionBankAttemptsProvider.overrideWith((ref) async => const []),
      questionBankTopicsProvider(
        1,
      ).overrideWith((ref) async => _topicsBySubject[1]!),
      questionBankTopicsProvider(
        2,
      ).overrideWith((ref) async => _topicsBySubject[2]!),
      questionBankTopicsProvider(3).overrideWith((ref) async => const []),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() => _practiceSelection = null);

  testWidgets('each subject shows only its own topics, no stale state', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Clinical Chemistry'), findsOneWidget);
    expect(find.text('Bacteriology'), findsOneWidget);

    await tester.tap(find.text('Clinical Chemistry'));
    await tester.pumpAndSettle();
    expect(find.text('Carbohydrates'), findsOneWidget);
    expect(find.text('Enzymes'), findsOneWidget);
    expect(find.text('Gram Stain'), findsNothing);

    // Back returns to the subject list.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose a subject from your registered course.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Bacteriology'));
    await tester.pumpAndSettle();
    expect(find.text('Gram Stain'), findsOneWidget);
    expect(find.text('Carbohydrates'), findsNothing);
    expect(find.text('Enzymes'), findsNothing);
  });

  testWidgets('selecting a topic passes subject and topic ids to practice', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clinical Chemistry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enzymes'));
    await tester.pumpAndSettle();

    expect(find.text('Practice screen'), findsOneWidget);
    expect(_practiceSelection!.subject.id, 1);
    expect(_practiceSelection!.topic.id, 11);
    expect(_practiceSelection!.topic.subjectId, 1);
  });

  testWidgets('subject without topics shows the empty state', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hematology'));
    await tester.pumpAndSettle();
    expect(
      find.text('No practice topics are available for this subject yet.'),
      findsOneWidget,
    );
  });

  testWidgets('topic load failure shows a safe message with retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          questionBankTopicsProvider(
            1,
          ).overrideWith((ref) async => throw Exception('PGRST301 raw')),
        ],
        child: MaterialApp(home: QuestionBankTopicsScreen(subject: _chem)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('We could not load the topics for this subject.'),
      findsOneWidget,
    );
    expect(find.textContaining('PGRST301'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });

  group('query scoping helpers', () {
    test('topics of other subjects are dropped', () {
      final topics = topicsFromRows([
        {'id': 10, 'subject_id': 1, 'title': 'Enzymes', 'description': null},
        {'id': 20, 'subject_id': 2, 'title': 'Gram Stain', 'description': ''},
        {'id': 30, 'subject_id': null, 'title': 'Orphan', 'description': ''},
      ], 1);
      expect(topics.map((t) => t.id), [10]);
      expect(topics.single.subjectId, 1);
    });

    test('questions of other topics are dropped', () {
      final rows = scopeQuestionRows([
        {'id': 1, 'quiz_id': 10, 'question_text': 'a'},
        {'id': 2, 'quiz_id': 11, 'question_text': 'b'},
        {'id': 3, 'quiz_id': '10', 'question_text': 'c'},
      ], 10);
      expect(rows.map((r) => r['id']), [1, 3]);
    });
  });
}
