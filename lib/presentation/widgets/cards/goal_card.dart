import 'package:flutter/material.dart';

/// A reusable card widget for displaying daily or periodic goals
/// with a checkbox/radio button to mark completion
class GoalCard extends StatelessWidget {
  final String date;
  final String title;
  final String details;
  final bool isChecked;
  final VoidCallback? onToggle;
  final EdgeInsetsGeometry? padding;

  const GoalCard({
    super.key,
    required this.date,
    required this.title,
    required this.details,
    required this.isChecked,
    this.onToggle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      padding: padding ?? const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                date,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RadioListTile<bool>(
            value: true,
            groupValue: isChecked,
            onChanged: onToggle != null ? (_) => onToggle!() : null,
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding: EdgeInsets.zero,
            title: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              details,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
