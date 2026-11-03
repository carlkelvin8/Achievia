import 'package:achievia/core/constants/app_assets.dart';
import 'package:flutter/material.dart';

/// Achievia branding introduction card with logo and description
class AchieviaIntroCard extends StatelessWidget {
  const AchieviaIntroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // The official logo with its wordmark. Its navy lettering needs a
          // light backdrop, so dark mode keeps a white plate behind it.
          Container(
            width: double.infinity,
            padding: isDark
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: isDark ? Colors.white : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              achieviaWordmark,
              key: const ValueKey('achievia-wordmark'),
              fit: BoxFit.contain,
              semanticLabel: 'Achievia, Awaken Academic Ambition',
            ),
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            'Achievia is a modern review platform designed to help students study smarter and excel in board exams through a convenient, innovative, and effective approach. Achievia offers curated materials and tools tailored to meet the needs of future board passers. With a growing community of dedicated users called Achievians, the platform continues to redefine how students prepare — with focus, flexibility, and results.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
