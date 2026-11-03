import 'package:achievia/core/utils/progress_aggregator.dart';
import 'package:achievia/data/models/progress/progress_snapshot_dto.dart';
import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:achievia/presentation/widgets/charts/progress/score_line_chart.dart';
import 'package:achievia/presentation/widgets/progress/score_graph_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> exam(
  String id,
  int subjectId,
  String subject,
  double score,
  String completedAt, {
  String type = 'subject_exam',
}) => {
  'id': id,
  'subject_id': subjectId,
  'subjects': {'title': subject},
  'score': score,
  'correct_answers': score.round(),
  'total_questions': 100,
  'completed_at': completedAt,
  'attempt_type': type,
};

ProgressEntity progressFrom({
  List<Map<String, dynamic>> attempts = const [],
  List<Map<String, dynamic>> mockBoards = const [],
}) => aggregateProgress(
  snapshot: ProgressSnapshotDto(
    activeDays: const [],
    studySessions: const [],
    quizAttempts: mockBoards,
    subjectExamAttempts: attempts,
  ),
  startDate: DateTime(2026, 9, 1),
  today: DateTime(2026, 9, 30),
);

Future<void> pump(WidgetTester t, ProgressEntity progress) async {
  t.view.physicalSize = const Size(400, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: ScoreGraphCard(progress: progress)),
      ),
    ),
  );
  await t.pumpAndSettle();
}

String subjectLabel(WidgetTester t) =>
    (t.widget(find.byKey(const ValueKey('graph-subject'))) as Text).data!;

List<ScoreData> chartData(WidgetTester t) =>
    t.widget<ScoreLineChart>(find.byType(ScoreLineChart)).data;

Future<void> tapKey(WidgetTester t, String key) async {
  await t.tap(find.byKey(ValueKey(key)));
  await t.pumpAndSettle();
}

void main() {
  final threeSubjects = [
    exam('a1', 1, 'Bacteriology', 60, '2026-09-10T02:00:00Z'),
    exam('a2', 1, 'Bacteriology', 80, '2026-09-05T02:00:00Z'),
    exam('b1', 2, 'Chemistry', 90, '2026-09-08T02:00:00Z'),
    exam('c1', 3, 'Hematology', 50, '2026-09-09T02:00:00Z'),
  ];

  testWidgets('shows one subject at a time between previous / next arrows', (
    t,
  ) async {
    await pump(t, progressFrom(attempts: threeSubjects));
    expect(subjectLabel(t), 'Bacteriology');
    expect(find.text('Average Score: 70.00%'), findsOneWidget);
    expect(find.byKey(const ValueKey('graph-prev')), findsOneWidget);
    expect(find.byKey(const ValueKey('graph-next')), findsOneWidget);
    // No mixed "all subjects" view any more.
    expect(find.text('All subjects'), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
  });

  testWidgets('right arrow moves forward and wraps to the first subject', (
    t,
  ) async {
    await pump(t, progressFrom(attempts: threeSubjects));
    await tapKey(t, 'graph-next');
    expect(subjectLabel(t), 'Chemistry');
    await tapKey(t, 'graph-next');
    expect(subjectLabel(t), 'Hematology');
    await tapKey(t, 'graph-next');
    expect(subjectLabel(t), 'Bacteriology');
  });

  testWidgets('left arrow moves back and wraps to the last subject', (t) async {
    await pump(t, progressFrom(attempts: threeSubjects));
    await tapKey(t, 'graph-prev');
    expect(subjectLabel(t), 'Hematology');
    await tapKey(t, 'graph-prev');
    expect(subjectLabel(t), 'Chemistry');
  });

  testWidgets('each subject shows only its own exams', (t) async {
    await pump(t, progressFrom(attempts: threeSubjects));
    expect(chartData(t).map((p) => p.score), [80, 60]);
    await tapKey(t, 'graph-next');
    expect(chartData(t).map((p) => p.score), [90]);
    expect(find.text('Average Score: 90.00%'), findsOneWidget);
    await tapKey(t, 'graph-next');
    expect(chartData(t).map((p) => p.score), [50]);
  });

  testWidgets('points are chronological, one per completed exam', (t) async {
    await pump(t, progressFrom(attempts: threeSubjects));
    final points = chartData(t);
    expect(points, hasLength(2));
    expect(points.first.date.isBefore(points.last.date), isTrue);
    expect(points.map((p) => p.score), [80, 60]); // Sep 5 then Sep 10
  });

  testWidgets('practice attempts never appear', (t) async {
    await pump(
      t,
      progressFrom(
        attempts: [
          ...threeSubjects,
          exam(
            'p1',
            1,
            'Bacteriology',
            10,
            '2026-09-11T02:00:00Z',
            type: 'practice',
          ),
          exam(
            'p2',
            9,
            'Practice Only',
            99,
            '2026-09-12T02:00:00Z',
            type: 'practice',
          ),
        ],
      ),
    );
    expect(chartData(t).map((p) => p.score), [80, 60]); // 10% practice ignored
    // The practice-only subject is not selectable at all.
    for (var i = 0; i < 4; i++) {
      expect(subjectLabel(t), isNot('Practice Only'));
      await tapKey(t, 'graph-next');
    }
  });

  testWidgets('Mock Board history never appears', (t) async {
    await pump(
      t,
      progressFrom(
        attempts: threeSubjects,
        mockBoards: [
          {
            'score': 95,
            'attempted_at': '2026-09-15',
            'answer': [
              {'name': 'Mock Board Subject', 'score': 95},
              {'name': 'Bacteriology', 'score': 100},
            ],
          },
        ],
      ),
    );
    expect(chartData(t).map((p) => p.score), [80, 60]);
    for (var i = 0; i < 4; i++) {
      expect(subjectLabel(t), isNot('Mock Board Subject'));
      await tapKey(t, 'graph-next');
    }
  });

  testWidgets('invalid attempts do not create points', (t) async {
    await pump(
      t,
      progressFrom(
        attempts: [
          exam('ok', 1, 'Bacteriology', 70, '2026-09-10T02:00:00Z'),
          exam('bad', 1, 'Bacteriology', 50, 'not a date'),
          {
            ...exam('bad2', 1, 'Bacteriology', 50, '2026-09-11T02:00:00Z'),
            'total_questions': 0,
          },
        ],
      ),
    );
    expect(chartData(t), hasLength(1));
  });

  testWidgets('one subject: arrows are disabled and nothing changes', (
    t,
  ) async {
    await pump(
      t,
      progressFrom(
        attempts: [exam('a', 1, 'Bacteriology', 70, '2026-09-10T02:00:00Z')],
      ),
    );
    final prev = t.widget<IconButton>(find.byKey(const ValueKey('graph-prev')));
    final next = t.widget<IconButton>(find.byKey(const ValueKey('graph-next')));
    expect(prev.onPressed, isNull);
    expect(next.onPressed, isNull);
    expect(subjectLabel(t), 'Bacteriology');
  });

  testWidgets('no subject exams gives a clean empty state', (t) async {
    await pump(t, progressFrom());
    expect(find.text('No completed subject exams yet'), findsOneWidget);
    expect(
      find.text('Complete a Take an Exam subject exam to see your scores.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('graph-prev')), findsNothing);
    expect(find.byKey(const ValueKey('graph-subject')), findsNothing);
  });

  testWidgets('only practice or Mock Board data is also an empty state', (
    t,
  ) async {
    await pump(
      t,
      progressFrom(
        attempts: [
          exam(
            'p',
            1,
            'Bacteriology',
            70,
            '2026-09-10T02:00:00Z',
            type: 'practice',
          ),
        ],
        mockBoards: [
          {
            'score': 88,
            'attempted_at': '2026-09-15',
            'answer': [
              {'name': 'Bacteriology', 'score': 88},
            ],
          },
        ],
      ),
    );
    expect(find.text('No completed subject exams yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('graph-next')), findsNothing);
  });

  testWidgets('a long subject name and large text scale do not overflow', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 700);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final progress = progressFrom(
      attempts: [
        exam(
          'a',
          1,
          'Immunohematology and Blood Banking ' * 3,
          70,
          '2026-09-10T02:00:00Z',
        ),
        exam('b', 2, 'Chemistry', 80, '2026-09-11T02:00:00Z'),
      ],
    );
    await t.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScoreGraphCard(progress: progress),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
}
