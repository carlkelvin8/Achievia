import 'package:flutter/material.dart';

class BuildBanner extends StatelessWidget {
  const BuildBanner({super.key});
    @override
    Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            'Medical Technology Dashboard',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}