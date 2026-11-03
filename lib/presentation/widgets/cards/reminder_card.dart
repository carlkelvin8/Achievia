import 'package:flutter/material.dart';
import 'package:achievia/core/constants/widget_paddings.dart';

/// A reusable card widget for displaying reminder/task items
/// Shows progress, title, subtitle, and due date
class ReminderCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String dueDateLabel;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final int? maxSubtitleLines;
  final bool isCompleted;
  final ValueChanged<bool>? onStatusChanged;

  const ReminderCard({
    super.key,
    required this.title,
    required this.dueDateLabel,
    this.subtitle,
    this.onTap,
    this.padding,
    this.margin,
    this.maxSubtitleLines = 3,
    this.isCompleted = false,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.only(top: 12, bottom: 4),
        padding: padding ?? level2Widget,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSecondary,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: GestureDetector(
                onTap: () => onStatusChanged?.call(!isCompleted),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? theme.colorScheme.primary : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                      width: 1.5,
                    ),
                  ),
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: maxSubtitleLines,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    dueDateLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
