import 'package:achievia/core/utils/duration_labels.dart';
import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:achievia/presentation/widgets/charts/progress/screentime_bar_chart.dart';
import 'package:achievia/presentation/widgets/progress/metric_item.dart';
import 'package:flutter/material.dart';

class ScreentimeCard extends StatelessWidget {
  final ScreentimeData data;
  final int todaySeconds;

  const ScreentimeCard({super.key, required this.data, this.todaySeconds = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Screentime',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Active app use on this device'),
          const SizedBox(height: 8),
          Text(
            'Today: ${formatTodayScreenTime(todaySeconds)}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          // Metrics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              MetricItem(
                label: 'Daily average',
                value: formatHoursMinutes(data.dailyAverage),
              ),
              MetricItem(
                label: 'Longest Screentime',
                value: formatHoursMinutes(data.longestScreentime),
              ),
              MetricItem(
                label: 'Shortest Screentime',
                value: formatHoursMinutes(data.shortestScreentime),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Screen time in mins',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: data.dailyBreakdown.any((day) => day.minutes > 0)
                ? 180
                : 80,
            child: ScreentimeBarChart(data: data.dailyBreakdown),
          ),
        ],
      ),
    );
  }
}
