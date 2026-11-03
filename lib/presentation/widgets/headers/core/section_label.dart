import 'package:flutter/material.dart';

/// A reusable section label widget for displaying section titles
/// Used throughout the app for consistent section headers
class SectionLabel extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry? padding;
  final TextStyle? style;

  const SectionLabel({
    super.key,
    required this.title,
    this.padding,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Text(
        title,
        style:
            style ??
            theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
