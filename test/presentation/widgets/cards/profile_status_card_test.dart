import 'package:achievia/presentation/widgets/cards/profile_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, double width, {String? university}) {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ProfileStatusCard(
            lastName: 'APP',
            firstName: 'TEST',
            middleName: 'ACHIEVIA',
            university:
                university ?? 'LPU-ST. CABRINI SCHOOL OF HEALTH SCIENCES INC.',
            dateOfExam: 'NOVEMBER 2026',
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final width in [320.0, 412.0, 800.0]) {
    testWidgets('keeps the ID ratio with no overflow at width $width', (
      tester,
    ) async {
      await _pump(tester, width);
      await tester.pump();
      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byType(ProfileStatusCard));
      expect(size.width / size.height, closeTo(340 / 214, 0.01));
    });
  }

  testWidgets('purpose is always MTLE and long values are truncated', (
    tester,
  ) async {
    await _pump(tester, 412);
    expect(find.text('MTLE'), findsOneWidget);
    final university = tester.widget<Text>(
      find.text('LPU-ST. CABRINI SCHOOL OF HEALTH SCIENCES INC.'),
    );
    expect(university.maxLines, 1);
    expect(university.overflow, TextOverflow.ellipsis);
    expect(find.text('MEDICAL TECHNOLOGIST'), findsOneWidget);
    expect(find.text('AWAKEN ACADEMIC AMBITION'), findsOneWidget);
  });
}
