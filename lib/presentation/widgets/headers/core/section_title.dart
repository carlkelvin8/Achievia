import 'package:flutter/material.dart';

/// A reusable section title widget for displaying bold section headers
/// Used in settings and configuration screens
class SectionTitle extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry? padding;
  final TextStyle? style;

  const SectionTitle({
    super.key,
    required this.title,
    this.padding,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        title,
        style: style ??
            theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
      ),
    );
  }
}
