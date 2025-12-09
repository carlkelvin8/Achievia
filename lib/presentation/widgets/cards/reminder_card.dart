import 'package:flutter/material.dart';
import 'package:achievia/core/constants/widget_paddings.dart';
import 'package:achievia/presentation/widgets/progress/progress_circle.dart';

/// A reusable card widget for displaying reminder/task items
/// Shows progress, title, subtitle, and due date
class ReminderCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String dueDateLabel;
  final double progress;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final int? maxSubtitleLines;

  const ReminderCard({
    super.key,
    required this.title,
    required this.dueDateLabel,
    this.subtitle,
    this.progress = 0.0,
    this.onTap,
    this.padding,
    this.margin,
    this.maxSubtitleLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.only(top: 12, bottom: 4),
        padding: padding ?? level2_widget,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSecondary,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: ProgressCircle(value: progress),
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
