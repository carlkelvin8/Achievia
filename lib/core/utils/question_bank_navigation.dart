import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Returns to the Question Bank subjects page without losing the screens
/// below it.
///
/// `context.go(subjects)` replaces the whole navigation stack, which left the
/// subjects page as the only page: its back button then had nowhere to go and
/// looked dead. Here the existing subjects page is revealed by popping the
/// pages above it, so Back keeps working all the way to where the user came
/// from. When the subjects page is not in the stack (restored or deep-linked
/// result), the Reviewers tab is put underneath it first.
void returnToQuestionBankSubjects(BuildContext context) {
  final router = GoRouter.of(context);
  final matches = router.routerDelegate.currentConfiguration.matches;
  final index = matches.lastIndexWhere(
    (match) => match.matchedLocation == RouteConstants.questionBankSubjects,
  );
  if (index >= 0) {
    var pops = matches.length - 1 - index;
    while (pops > 0 && router.canPop()) {
      router.pop();
      pops--;
    }
    return;
  }
  router.go(RouteConstants.reviewers);
  router.push(RouteConstants.questionBankSubjects);
}
