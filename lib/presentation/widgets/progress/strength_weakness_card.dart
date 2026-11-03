import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:achievia/presentation/widgets/progress/subject_row.dart';
import 'package:flutter/material.dart';

class StrengthWeaknessCard extends StatelessWidget {
  final StrengthWeakness data;

  const StrengthWeaknessCard({super.key, required this.data});

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
            'Your Strength and Weakness as an Achievian',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          // Best Subject
          SubjectRow(
            label: 'Best',
            subject: data.bestSubject,
            average: data.bestAverage,
            isBest: true,
            hasData: data.bestSubject != 'N/A',
          ),
          const SizedBox(height: 12),
          // Weakest Subject (needs at least two subjects with exam data)
          SubjectRow(
            label: 'Weakest',
            subject: data.weakestSubject,
            average: data.weakestAverage,
            isBest: false,
            hasData: data.weakestSubject != 'N/A',
          ),
        ],
      ),
    );
  }
}
