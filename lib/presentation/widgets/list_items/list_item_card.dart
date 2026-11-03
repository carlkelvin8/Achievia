import 'package:flutter/material.dart';
import 'package:achievia/core/constants/widget_paddings.dart';

/// A reusable list item card with icon, label, and optional trailing widget
/// Commonly used for navigable menu items or settings
class ListItemCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingText;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ListItemCard({
    super.key,
    required this.icon,
    required this.label,
    this.trailingText,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? level2Widget,
        margin: margin,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSecondary,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        width: width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor ?? theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(label, style: theme.textTheme.labelMedium),
              ],
            ),
            trailing ??
                (trailingText != null
                    ? Text(trailingText!, style: theme.textTheme.labelMedium)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
