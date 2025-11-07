import 'package:achievia/domain/entities/progress_entity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ScoreLineChart extends StatelessWidget {
  final List<ScoreData> data;

  const ScoreLineChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

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
        minimum: data.map((e) => e.score).reduce((a, b) => a < b ? a : b) - 5,
        maximum: data.map((e) => e.score).reduce((a, b) => a > b ? a : b) + 5,
        interval: 5,
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
          xValueMapper: (_ChartData data, _) => data.dateLabel,
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

