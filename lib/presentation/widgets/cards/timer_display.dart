import 'package:flutter/material.dart';

/// A reusable timer display widget showing time and phase information
/// Perfect for countdown timers, pomodoro timers, or any time-based features
class TimerDisplay extends StatelessWidget {
  final String phaseLabel;
  final String timeDisplay;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? phaseLabelStyle;
  final TextStyle? timeDisplayStyle;

  const TimerDisplay({
    super.key,
    required this.phaseLabel,
    required this.timeDisplay,
    this.actions,
    this.padding,
    this.margin,
    this.phaseLabelStyle,
    this.timeDisplayStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            phaseLabel,
            style: phaseLabelStyle ??
                theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            timeDisplay,
            style: timeDisplayStyle ??
                theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}
