import 'package:flutter/material.dart';

/// A reusable content section widget with title and body text
/// Commonly used for displaying messages, descriptions, or articles
class ContentSection extends StatelessWidget {
  final String title;
  final String content;
  final TextStyle? titleStyle;
  final TextStyle? contentStyle;
  final double spacing;
  final CrossAxisAlignment alignment;
  final EdgeInsetsGeometry? padding;

  const ContentSection({
    super.key,
    required this.title,
    required this.content,
    this.titleStyle,
    this.contentStyle,
    this.spacing = 16,
    this.alignment = CrossAxisAlignment.start,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(
            title,
            style: titleStyle ??
                theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
          ),
          SizedBox(height: spacing),
          Text(
            content,
            style: contentStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
