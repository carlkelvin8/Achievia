import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:achievia/presentation/widgets/charts/progress/score_line_chart.dart';
import 'package:achievia/presentation/widgets/progress/screentime_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  test('score percent text carries exactly one percent sign', () {
    expect(formatScorePercent(25), '25%');
    expect(formatScorePercent(33.5), '33.5%');
    expect(formatScorePercent(0), '0%');
    expect(formatScorePercent(100), '100%');
    expect(
      'Series 0, 1. Oct 12, 2026: ${formatScorePercent(25)}'.split('%'),
      hasLength(2),
    );
  });

  testWidgets('score tooltip adds no second % to the axis format', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScoreLineChart(
            data: [ScoreData(date: DateTime(2026, 10, 12), score: 25)],
          ),
        ),
      ),
    );
    final chart = tester.widget<SfCartesianChart>(
      find.byType(SfCartesianChart),
    );
    final axis = chart.primaryYAxis as NumericAxis;
    expect(axis.labelFormat, '{value}%');
    // The value already carries the axis "%": exactly one in "25%".
    expect(chart.tooltipBehavior!.format, 'point.x : point.y');
    expect(chart.tooltipBehavior!.format, isNot(contains('%')));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('screen time shows hours and minutes', (tester) async {
    final data = ScreentimeData(
      dailyAverage: 148,
      longestScreentime: 61,
      shortestScreentime: 45,
      dailyBreakdown: [
        DailyScreentime(date: DateTime(2026, 10, 12), minutes: 148),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScreentimeCard(data: data, todaySeconds: 148 * 60 + 4),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Today: 2 hrs & 28 mins'), findsOneWidget);
    expect(find.text('2 hrs & 28 mins'), findsOneWidget);
    expect(find.text('1 hr & 1 min'), findsOneWidget);
    expect(find.text('45 mins'), findsOneWidget);
    expect(find.text('148 min'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}
