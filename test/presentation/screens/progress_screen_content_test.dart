import 'package:achievia/presentation/provider/progress/progress_provider.dart';
import 'package:achievia/presentation/screens/screen_contents/progress_screen_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:achievia/presentation/provider/progress/screentime_provider.dart';
import 'package:achievia/core/utils/progress_aggregator.dart';
import 'package:achievia/data/models/progress/progress_snapshot_dto.dart';
import 'package:achievia/presentation/widgets/progress/score_graph_card.dart';
import 'package:achievia/presentation/widgets/progress/strength_weakness_card.dart';
import 'package:achievia/presentation/widgets/progress/screentime_card.dart';

void main() {
  testWidgets(
    'empty progress cards fill phone width and explain missing data',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final progress = aggregateProgress(
        snapshot: const ProgressSnapshotDto(
          activeDays: [],
          quizAttempts: [],
          studySessions: [],
        ),
        startDate: DateTime(2026, 9, 26),
        today: DateTime(2026, 9, 26),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressProvider.overrideWith((ref) async => progress),
            screentimeUserProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(home: ProgressScreenContent()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No completed subject exams yet'), findsOneWidget);
      expect(
        find.textContaining('first minute of active app use'),
        findsOneWidget,
      );
      expect(find.text('N/A'), findsNothing);
      final width = tester.getSize(find.byType(StrengthWeaknessCard)).width;
      expect(width, greaterThan(330));
      expect(tester.getSize(find.byType(ScoreGraphCard)).width, width);
      expect(tester.getSize(find.byType(ScreentimeCard)).width, width);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'score average describes the selected subject\'s exams, not Mock Board',
    (tester) async {
      final progress = aggregateProgress(
        snapshot: const ProgressSnapshotDto(
          activeDays: [],
          studySessions: [],
          subjectExamAttempts: [
            {
              'id': 'e1',
              'subject_id': 1,
              'subjects': {'title': 'Chemistry'},
              'score': 60,
              'correct_answers': 60,
              'total_questions': 100,
              'completed_at': '2026-09-25T02:00:00Z',
              'attempt_type': 'subject_exam',
            },
            {
              'id': 'e2',
              'subject_id': 1,
              'subjects': {'title': 'Chemistry'},
              'score': 80,
              'correct_answers': 80,
              'total_questions': 100,
              'completed_at': '2026-09-26T02:00:00Z',
              'attempt_type': 'subject_exam',
            },
          ],
          // Mock Board style rows must not feed the subject graph.
          quizAttempts: [
            {
              'score': 60,
              'attempted_at': '2026-09-25',
              'answer': [
                {'name': 'Chemistry', 'score': 90},
              ],
            },
            {
              'score': 80,
              'attempted_at': '2026-09-26',
              'answer': [
                {'name': 'Chemistry', 'score': 100},
              ],
            },
          ],
        ),
        startDate: DateTime(2026, 9, 25),
        today: DateTime(2026, 9, 26),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScoreGraphCard(progress: progress)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Average Score: 70.00%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('progress failure shows fallback instead of retrying forever', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          screentimeUserProvider.overrideWithValue(null),
          progressProvider.overrideWith(
            (ref) async => throw Exception('permanent database error'),
          ),
        ],
        child: const MaterialApp(home: ProgressScreenContent()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text('Unable to load quiz progress. Pull down to retry.'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
