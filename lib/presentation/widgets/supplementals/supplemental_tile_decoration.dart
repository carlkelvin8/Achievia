import 'package:flutter/material.dart';

BoxDecoration supplementalTileDecoration(ThemeData theme) {
  return BoxDecoration(
    color: theme.colorScheme.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: theme.colorScheme.outline.withValues(alpha: 0.16),
    ),
    boxShadow: [
      BoxShadow(
        color: theme.colorScheme.shadow.withValues(alpha: 0.10),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class EmptySupplementalSection extends StatelessWidget {
  const EmptySupplementalSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          'No resources found',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
