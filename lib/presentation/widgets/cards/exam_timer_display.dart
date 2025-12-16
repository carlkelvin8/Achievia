import 'package:flutter/material.dart';

/// A reusable timer display widget showing time and phase information
/// Perfect for countdown timers, pomodoro timers, or any time-based features
class ExamTimerDisplay extends StatelessWidget {
  final String phaseLabel;
  final String timeDisplay;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? phaseLabelStyle;
  final TextStyle? timeDisplayStyle;

  const ExamTimerDisplay({
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
      padding: padding ?? const EdgeInsets.only(left: 70, right: 70, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            timeDisplay,
            style: timeDisplayStyle ??
                theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white
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
