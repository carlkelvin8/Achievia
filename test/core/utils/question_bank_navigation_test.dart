import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/question_bank_navigation.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter buildRouter({String initial = RouteConstants.reviewers}) {
  Widget page(String name, {bool backToSubjects = false}) => Scaffold(
    appBar: AppBar(title: Text(name)),
    body: Builder(
      builder: (context) => backToSubjects
          ? TextButton(
              onPressed: () => returnToQuestionBankSubjects(context),
              child: const Text('Back to subjects'),
            )
          : Text(name),
    ),
  );
  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: RouteConstants.reviewers,
        builder: (_, _) => page('Reviewers'),
      ),
      GoRoute(
        path: RouteConstants.questionBank,
        builder: (_, _) => page('QuestionBank'),
      ),
      GoRoute(
        path: RouteConstants.questionBankSubjects,
        builder: (_, _) => page('Subjects'),
      ),
      GoRoute(
        path: RouteConstants.questionBankTopics,
        builder: (_, _) => page('Topics'),
      ),
      GoRoute(
        path: RouteConstants.questionBankResults,
        builder: (_, _) => page('Results', backToSubjects: true),
      ),
    ],
  );
}

Future<GoRouter> pumpApp(WidgetTester tester, GoRouter router) async {
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('back from results reveals subjects and keeps the stack', (
    tester,
  ) async {
    final router = await pumpApp(tester, buildRouter());
    router.push(RouteConstants.questionBank);
    await tester.pumpAndSettle();
    router.push(RouteConstants.questionBankSubjects);
    await tester.pumpAndSettle();
    router.push(RouteConstants.questionBankTopics);
    await tester.pumpAndSettle();
    router.push(RouteConstants.questionBankResults);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back to subjects'));
    await tester.pumpAndSettle();
    expect(find.text('Subjects'), findsWidgets);
    expect(find.text('Results'), findsNothing);
    expect(find.text('Topics'), findsNothing);
    expect(router.canPop(), isTrue, reason: 'the back button must work');

    // Back from subjects goes where the user came from.
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('QuestionBank'), findsWidgets);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Reviewers'), findsWidgets);
  });

  testWidgets('a restored result with no stack still gets a working back', (
    tester,
  ) async {
    final router = await pumpApp(
      tester,
      buildRouter(initial: RouteConstants.questionBankResults),
    );
    expect(router.canPop(), isFalse);

    await tester.tap(find.text('Back to subjects'));
    await tester.pumpAndSettle();
    expect(find.text('Subjects'), findsWidgets);
    expect(router.canPop(), isTrue, reason: 'subjects must not be a dead end');

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Reviewers'), findsWidgets);
  });

  testWidgets('works when subjects is the page right below results', (
    tester,
  ) async {
    final router = await pumpApp(
      tester,
      buildRouter(initial: RouteConstants.questionBankSubjects),
    );
    router.push(RouteConstants.questionBankResults);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back to subjects'));
    await tester.pumpAndSettle();
    expect(find.text('Subjects'), findsWidgets);
    expect(find.text('Results'), findsNothing);
  });

  testWidgets('the app bar arrow of a lone page goes to main, not nowhere', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: RouteConstants.questionBankSubjects,
      routes: [
        GoRoute(
          path: RouteConstants.main,
          builder: (_, _) => const Scaffold(body: Text('Main page')),
        ),
        GoRoute(
          path: RouteConstants.questionBankSubjects,
          builder: (_, _) => const Scaffold(
            appBar: CustomAppBar(title: 'Question Bank'),
            body: Text('Subjects page'),
          ),
        ),
      ],
    );
    await pumpApp(tester, router);
    expect(router.canPop(), isFalse);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Main page'), findsOneWidget);
  });
}
