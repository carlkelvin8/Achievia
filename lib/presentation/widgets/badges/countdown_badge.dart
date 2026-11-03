import 'package:flutter/material.dart';

/// A reusable countdown badge widget displaying remaining days
/// Perfect for exam countdowns, deadline displays, or time-sensitive information
class CountdownBadge extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onValueTap;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? valueColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? badgePadding;

  const CountdownBadge({
    super.key,
    required this.label,
    required this.value,
    this.onValueTap,
    this.backgroundColor,
    this.textColor,
    this.valueColor,
    this.padding,
    this.badgePadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: textColor ?? theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          MouseRegion(
            cursor: onValueTap != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: onValueTap,
              child: Container(
                padding:
                    badgePadding ??
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: backgroundColor ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
