import 'package:flutter/material.dart';

/// A reusable circular progress indicator widget
/// Shows progress as a circular ring with customizable colors
class ProgressCircle extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? valueColor;
  final Widget? child;

  const ProgressCircle({
    super.key,
    required this.value,
    this.size = 22,
    this.strokeWidth = 3,
    this.backgroundColor,
    this.valueColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value.clamp(0.0, 1.0),
            strokeWidth: strokeWidth,
            backgroundColor: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              valueColor ?? theme.colorScheme.primary,
            ),
          ),
          child ??
              Container(
                width: size - (strokeWidth * 3),
                height: size - (strokeWidth * 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSecondary,
                  shape: BoxShape.circle,
                ),
              ),
        ],
      ),
    );
  }
}
