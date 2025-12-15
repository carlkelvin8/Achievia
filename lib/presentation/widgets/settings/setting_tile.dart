import 'package:flutter/material.dart';

/// A reusable setting tile with label, value display, and increment/decrement controls
/// Commonly used for adjusting numeric settings like duration, count, etc.
class SettingTile extends StatelessWidget {
  final String label;
  final String valueLabel;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double controlWidth;

  const SettingTile({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.onIncrement,
    required this.onDecrement,
    this.onTap,
    this.padding,
    this.controlWidth = 150,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          SizedBox(
            width: controlWidth,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundIconButton(
                      icon: Icons.remove,
                      onPressed: onDecrement,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          valueLabel,
                          style: theme.textTheme.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    _RoundIconButton(
                      icon: Icons.add,
                      onPressed: onIncrement,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
      ),
    );
  }
}
