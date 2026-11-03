import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_subjects_screen.dart';
import 'package:achievia/presentation/screens/question_bank/question_bank_topics_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/questions_content_screen.dart';
import 'package:achievia/presentation/widgets/reviewers/reviewer_category_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('Question Bank card opens its own subject screen', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/bank',
      routes: [
        GoRoute(
          path: '/bank',
          builder: (_, _) => const QuestionsContentScreen(),
        ),
        GoRoute(
          path: '/question-bank/subjects',
          builder: (_, _) => const Scaffold(body: Text('Subject picker')),
        ),
        GoRoute(
          path: '/onboarding-questions',
          builder: (_, _) => const Scaffold(body: Text('Mock Boards setup')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Question Bank'));
    await tester.pumpAndSettle();

    expect(find.text('Subject picker'), findsOneWidget);
    expect(find.text('Mock Boards setup'), findsNothing);
  });

  testWidgets('subject screen renders only provided course subjects', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          questionBankSubjectsProvider.overrideWith(
            (ref) async => const [_subject],
          ),
          recentQuestionBankAttemptsProvider.overrideWith(
            (ref) async => const [],
          ),
        ],
        child: const MaterialApp(home: QuestionBankSubjectsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Choose a subject from your registered course.'),
      findsOneWidget,
    );
    expect(find.text('Clinical Chemistry'), findsOneWidget);
    expect(find.text('Hematology'), findsNothing);
  });

  testWidgets('subject screen omits placeholder null descriptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          questionBankSubjectsProvider.overrideWith(
            (ref) async => const [_nullDescriptionSubject],
          ),
          recentQuestionBankAttemptsProvider.overrideWith(
            (ref) async => const [],
          ),
        ],
        child: const MaterialApp(home: QuestionBankSubjectsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hematology'), findsOneWidget);
    expect(find.text('NULL'), findsNothing);
    expect(find.text('Practice this subject'), findsNothing);
  });

  testWidgets('subject screen explains a missing course assignment', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          questionBankSubjectsProvider.overrideWith(
            (ref) async => throw const QuestionBankCourseMissingException(),
          ),
          recentQuestionBankAttemptsProvider.overrideWith(
            (ref) async => const [],
          ),
        ],
        child: const MaterialApp(home: QuestionBankSubjectsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Your profile needs a course assignment before you can practice.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('topic screen renders topics for the selected subject', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          questionBankTopicsProvider(
            _subject.id,
          ).overrideWith((ref) async => const [_topic]),
        ],
        child: const MaterialApp(
          home: QuestionBankTopicsScreen(subject: _subject),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Clinical Chemistry'), findsOneWidget);
    expect(find.text('Enzymes'), findsOneWidget);
    // Plain rows: no "Study deck" label and no leading icon.
    expect(find.text('Study deck'), findsNothing);
    expect(find.byIcon(Icons.quiz_outlined), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ReviewerCategoryCard),
        matching: find.byType(Icon),
      ),
      findsOneWidget,
      reason: 'only the chevron',
    );
  });
}

const _subject = QuestionBankSubject(
  id: 1,
  courseId: 4,
  title: 'Clinical Chemistry',
  description: 'Chemistry concepts and laboratory practice.',
  image: '',
);

const _nullDescriptionSubject = QuestionBankSubject(
  id: 2,
  courseId: 4,
  title: 'Hematology',
  description: 'NULL',
  image: '',
);

const _topic = QuestionBankTopic(
  id: 8,
  subjectId: 1,
  title: 'Enzymes',
  description: '',
);
