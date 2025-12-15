import 'package:flutter/material.dart';

/// A reusable back button with text label
/// Commonly used in app bars for navigation with context
class BackButtonWithLabel extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;
  final double iconSize;

  const BackButtonWithLabel({
    super.key,
    required this.label,
    this.onTap,
    this.iconColor,
    this.textColor,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back,
              color: iconColor ?? theme.colorScheme.primary,
              size: iconSize,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor ?? theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
