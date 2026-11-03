import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// "25%" for whole scores, "33.5%" otherwise; one percent sign, always.
String formatScorePercent(double score) {
  final rounded = score.roundToDouble();
  final text = score == rounded
      ? rounded.toInt().toString()
      : score.toStringAsFixed(1);
  return '$text%';
}

class ScoreLineChart extends StatelessWidget {
  final List<ScoreData> data;
  final String emptyMessage;

  const ScoreLineChart({
    super.key,
    required this.data,
    this.emptyMessage =
        'Complete a Mock Board or Question Bank quiz to see your scores.',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Text(emptyMessage, textAlign: TextAlign.center));
    }
    final theme = Theme.of(context);
    final chartData = data
        .map(
          (item) => _ChartData(
            date: item.date,
            score: item.score,
            dateLabel: DateFormat('MMM d, yyyy').format(item.date),
          ),
        )
        .toList();

    return SfCartesianChart(
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.x : point.y',
      ),
      // The percent sign is written exactly once, here: "1. Oct 12, 2026: 25%".
      onTooltipRender: (TooltipArgs args) {
        final index = args.pointIndex?.toInt();
        if (index == null || index < 0 || index >= chartData.length) return;
        final point = chartData[index];
        args.text =
            '${index + 1}. ${point.dateLabel}: '
            '${formatScorePercent(point.score)}';
      },
      plotAreaBorderWidth: 0,
      primaryXAxis: CategoryAxis(
        labelRotation: -45,
        labelStyle: TextStyle(
          fontSize: 9,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: AxisLine(
          width: 1,
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: 100,
        interval: 20,
        labelFormat: '{value}%',
        labelStyle: TextStyle(
          fontSize: 10,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        majorGridLines: MajorGridLines(
          width: 1,
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        axisLine: AxisLine(
          width: 1,
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      series: <CartesianSeries<_ChartData, String>>[
        LineSeries<_ChartData, String>(
          dataSource: chartData,
          xValueMapper: (_ChartData data, index) =>
              '${index + 1}. ${data.dateLabel}',
          yValueMapper: (_ChartData data, _) => data.score,
          color: theme.colorScheme.primary,
          width: 3,
          markerSettings: MarkerSettings(
            isVisible: true,
            height: 8,
            width: 8,
            shape: DataMarkerType.circle,
            borderWidth: 2,
            borderColor: theme.colorScheme.primary,
            color: Colors.white,
          ),
          dataLabelSettings: DataLabelSettings(isVisible: false),
        ),
      ],
    );
  }
}

// Chart data model
class _ChartData {
  final DateTime date;
  final double score;
  final String dateLabel;

  _ChartData({
    required this.date,
    required this.score,
    required this.dateLabel,
  });
}
