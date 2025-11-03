import 'package:flutter/material.dart';

class ExpandableItem extends StatelessWidget {
  final String title;
  final String? description;
  final bool isExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final IconData? icon;

  final String? imagePath;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final double iconSize;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  final Widget? expandedChild;

  const ExpandableItem({
    super.key,
    required this.title,
    this.description,
    required this.isExpanded,
    this.onExpandedChanged,
    this.icon,
    this.imagePath,
    this.iconBackgroundColor,
    this.iconColor,
    this.iconSize = 40,
    this.borderRadius = 6,
    this.contentPadding,
    this.expandedChild,
  }) : assert(
         icon != null || imagePath != null,
         'Either icon or imagePath must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // If imagePath is provided and no explicit background color is set, use transparent
    // Otherwise, use primary color for icons
    final backgroundColor =
        iconBackgroundColor ??
        (imagePath != null ? Colors.transparent : theme.colorScheme.primary);
    final iconColorValue = iconColor ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onExpandedChanged != null
                ? () => onExpandedChanged!(!isExpanded)
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding:
                  contentPadding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Icon/Image in colored square (or transparent for images)
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: backgroundColor == Colors.transparent
                        ? null
                        : BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(borderRadius),
                          ),
                    child: imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(borderRadius),
                            child: Image.asset(
                              imagePath!,
                              width: iconSize,
                              height: iconSize,
                              fit: BoxFit.contain,
                            ),
                          )
                        : icon != null
                        ? Icon(
                            icon,
                            color: iconColorValue,
                            size: iconSize * 0.5,
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: EdgeInsets.fromLTRB(iconSize + 12 + 16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child:
                    expandedChild ??
                    (description != null && description!.isNotEmpty
                        ? Text(
                            description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          )
                        : const SizedBox.shrink()),
              ),
            ),
        ],
      ),
    );
  }
}
