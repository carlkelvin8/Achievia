import 'package:achievia/domain/entities/progress_entity.dart';
import 'package:flutter/material.dart';

class GradingBracketTable extends StatelessWidget {
  final List<GradingBracket> brackets;

  const GradingBracketTable({super.key, required this.brackets});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Self Assessment Title
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Self Assessment',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        // Table Container
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Achievia Grading Bracket',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Table
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2.5),
                  2: FlexColumnWidth(3.5),
                },
                children: [
                  // Header Row
                  TableRow(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    children: [
                      _buildTableCell(context, 'SCORE RANGE', isHeader: true),
                      _buildTableCell(context, 'LEVEL', isHeader: true),
                      _buildTableCell(context, 'MESSAGE', isHeader: true),
                    ],
                  ),
                  // Data Rows
                  ...brackets.map(
                    (bracket) => TableRow(
                      children: [
                        _buildTableCell(context, bracket.scoreRange),
                        _buildTableCell(context, bracket.level),
                        _buildTableCell(context, bracket.message),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(
    BuildContext context,
    String text, {
    bool isHeader = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: isHeader
            ? theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              )
            : theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}
