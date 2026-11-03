import 'dart:io';

import 'package:achievia/presentation/widgets/list_items/logo_meaning_section.dart';
import 'package:achievia/presentation/widgets/list_items/mission_vision_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {Size size = const Size(360, 640)}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1)),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('Mission, Vision & Core Values', () {
    testWidgets('Mission and Vision text matches the client copy exactly', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: _wrap(
            const MissionVisionSection(),
            size: const Size(360, 640),
          ),
        ),
      );

      // Mission is expanded by default.
      expect(
        find.text(
          'We empower learners to transform challenges into opportunities. Through purposeful, inclusive, and values-driven education, we ignite curiosity, build resilience, and inspire excellence. With innovation and integrity, we rise together.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Vision'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'To become the leading platform for transformative, inclusive learning, where dreams are nurtured, differences are celebrated, and every learner is equipped to succeed with confidence, purpose, and pride.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Core Values lists all eight A-C-H-I-E-V-I-A values', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: _wrap(const MissionVisionSection())),
      );

      await tester.tap(find.text('Core Values'));
      await tester.pumpAndSettle();

      const labels = [
        'Aspiration',
        'Commitment',
        'Honesty',
        'Innovation',
        'Excellence',
        'Values',
        'Inclusivity',
        'Achievement',
      ];
      for (final label in labels) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(
        find.text(
          'Achie-via inclusivity by embracing differences, creating equal opportunities, and ensuring every learner feels respected, supported, and empowered.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders on a small Android phone without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(child: _wrap(const MissionVisionSection())),
      );
      await tester.tap(find.text('Core Values'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('survives large text scaling', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: const MissionVisionSection(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Core Values'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Core Values'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Logo meaning', () {
    testWidgets('shows the five client-supplied logo meanings', (tester) async {
      await tester.pumpWidget(
        ProviderScope(child: _wrap(const LogoMeaningSection())),
      );

      const titles = [
        'Peak',
        'Ups and Downs',
        'Mistakes & Curiosity',
        'Corrections and Improvements',
        'Rest & Wellness',
      ];
      for (final title in titles) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      // The previous "Official Logo" entry is gone.
      expect(find.text('Official Logo'), findsNothing);
    });

    test('Rest & Wellness uses the supplied icon (Logo2_1)', () {
      final source = File(
        'lib/presentation/widgets/list_items/logo_meaning_section.dart',
      ).readAsStringSync();
      final rest = source.substring(source.indexOf("'Rest & Wellness'"));
      expect(rest, contains("imagePath: 'assets/images/LOGO/Logo2_1.svg'"));
      expect(File('assets/images/LOGO/Logo2_1.svg').existsSync(), isTrue);
    });

    testWidgets('logo descriptions match the client copy exactly', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: _wrap(const LogoMeaningSection())),
      );

      // Peak is expanded by default.
      expect(
        find.text(
          'The “A” symbolizes aspiration and ambition. It stands tall as a marker of excellence, beginning every learner’s climb to success.',
        ),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Rest & Wellness'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rest & Wellness'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'The intentional spaces in the logo stand for mental wellness. Rest isn’t a pause in learning. It’s part of it.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('expansion state toggles through the provider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(child: _wrap(const LogoMeaningSection())),
      );

      // Ups and Downs starts collapsed; tapping expands it via the provider.
      expect(find.textContaining('real learning journey'), findsNothing);
      await tester.tap(find.text('Ups and Downs'));
      await tester.pumpAndSettle();
      expect(find.textContaining('real learning journey'), findsOneWidget);

      await tester.tap(find.text('Ups and Downs'));
      await tester.pumpAndSettle();
      expect(find.textContaining('real learning journey'), findsNothing);
    });
  });
}
