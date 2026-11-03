import 'package:achievia/presentation/screens/screen_contents/contents/achievia_content_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('logo meaning comes before mission, vision and core values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AchieviaContentScreen())),
    );
    await tester.pump();

    final logo = tester.getTopLeft(
      find.text('The Meaning Behind the Achievia Logo'),
    );
    final mission = tester.getTopLeft(find.text('Our Purpose & Principles'));
    final legal = tester.getTopLeft(find.text('Legal & Policies'));
    expect(logo.dy, lessThan(mission.dy));
    expect(mission.dy, lessThan(legal.dy));
  });
}
