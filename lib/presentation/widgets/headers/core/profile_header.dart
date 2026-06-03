import 'package:flutter/material.dart';

/// A reusable profile header widget with image, name, and subtitle info
/// Commonly used for user profiles, author cards, etc.
class ProfileHeader extends StatelessWidget {
  final Widget imageWidget;
  final String name;
  final String? subtitle1;
  final String? subtitle2;
  final TextStyle? nameStyle;
  final TextStyle? subtitle1Style;
  final TextStyle? subtitle2Style;
  final double spacing;
  final CrossAxisAlignment alignment;

  const ProfileHeader({
    super.key,
    required this.imageWidget,
    required this.name,
    this.subtitle1,
    this.subtitle2,
    this.nameStyle,
    this.subtitle1Style,
    this.subtitle2Style,
    this.spacing = 4,
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: alignment,
      children: [
        imageWidget,
        const SizedBox(height: 16),
        Text(
          name,
          textAlign: TextAlign.center,
          style: nameStyle ??
              theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
        ),
        if (subtitle1 != null) ...[
          SizedBox(height: spacing),
          Text(
            subtitle1!,
            textAlign: TextAlign.center,
            style: subtitle1Style ??
                theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
        if (subtitle2 != null) ...[
          SizedBox(height: spacing),
          Text(
            subtitle2!,
            textAlign: TextAlign.center,
            style: subtitle2Style ??
                theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ],
    );
  }
}
