import 'package:achievia/core/constants/study_tips.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/study_tips_content_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('banner, all 15 tips in order, then the reminder', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StudyTipsContentScreen()));
    await tester.pumpAndSettle();

    expect(studyTips, hasLength(15));
    expect(find.byKey(const ValueKey('study-tips-banner')), findsOneWidget);

    final list = find.byKey(const ValueKey('study-tips-list'));
    for (var n = 1; n <= studyTips.length; n++) {
      final tip = find.byKey(ValueKey('study-tip-$n'));
      await tester.scrollUntilVisible(
        tip,
        200,
        scrollable: find.descendant(
          of: list,
          matching: find.byType(Scrollable),
        ),
      );
      expect(
        find.descendant(of: tip, matching: find.text(studyTips[n - 1].title)),
        findsOneWidget,
      );
    }
    final reminder = find.byKey(const ValueKey('study-tips-reminder'));
    await tester.scrollUntilVisible(
      reminder,
      200,
      scrollable: find.descendant(of: list, matching: find.byType(Scrollable)),
    );
    expect(reminder, findsOneWidget);
    // The reminder comes after the last tip.
    expect(
      tester.getTopLeft(reminder).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const ValueKey('study-tip-15'))).dy,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
