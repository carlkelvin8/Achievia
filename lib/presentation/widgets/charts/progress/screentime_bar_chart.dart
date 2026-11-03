import 'package:achievia/core/utils/duration_labels.dart';
import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ScreentimeBarChart extends StatelessWidget {
  final List<DailyScreentime> data;

  const ScreentimeBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.every((day) => day.minutes == 0)) {
      return const Center(
        child: Text(
          'Your chart will appear after your first minute of active app use.',
          textAlign: TextAlign.center,
        ),
      );
    }
    final theme = Theme.of(context);
    final chartData = data
        .map(
          (item) => _BarChartData(
            date: item.date,
            minutes: item.minutes,
            dateLabel: DateFormat('MMM d').format(item.date),
          ),
        )
        .toList();

    return SfCartesianChart(
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.x : point.y min',
      ),
      // Same tooltip, with the minutes shown as hours and minutes.
      onTooltipRender: (TooltipArgs args) {
        final index = args.pointIndex?.toInt();
        if (index == null || index < 0 || index >= chartData.length) return;
        final point = chartData[index];
        args.text = '${point.dateLabel} : ${formatHoursMinutes(point.minutes)}';
      },
      plotAreaBorderWidth: 0,
      primaryXAxis: CategoryAxis(
        labelRotation: -45,
        labelStyle: TextStyle(
          fontSize: 8,
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
      series: <CartesianSeries<_BarChartData, String>>[
        ColumnSeries<_BarChartData, String>(
          dataSource: chartData,
          xValueMapper: (_BarChartData data, _) => data.dateLabel,
          yValueMapper: (_BarChartData data, _) => data.minutes,
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          dataLabelSettings: DataLabelSettings(isVisible: false),
        ),
      ],
    );
  }
}

// Chart data model
class _BarChartData {
  final DateTime date;
  final int minutes;
  final String dateLabel;

  _BarChartData({
    required this.date,
    required this.minutes,
    required this.dateLabel,
  });
}
