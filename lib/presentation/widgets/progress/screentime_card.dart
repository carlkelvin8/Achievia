import 'package:achievia/domain/entities/progress_entity.dart';
import 'package:achievia/presentation/widgets/charts/progress/screentime_bar_chart.dart';
import 'package:achievia/presentation/widgets/progress/metric_item.dart';
import 'package:flutter/material.dart';

class ScreentimeCard extends StatelessWidget {
  final ScreentimeData data;

  const ScreentimeCard({super.key, required this.data});

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
          // Metrics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              MetricItem(
                label: 'Daily average',
                value: '${data.dailyAverage} min',
              ),
              MetricItem(
                label: 'Longest Screentime',
                value: '${data.longestScreentime} mins',
              ),
              MetricItem(
                label: 'Shortest Screentime',
                value: '${data.shortestScreentime} minutes',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Screen time in minutes',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: ScreentimeBarChart(data: data.dailyBreakdown),
          ),
        ],
      ),
    );
  }
}
