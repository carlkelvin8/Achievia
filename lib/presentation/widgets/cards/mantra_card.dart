import 'package:achievia/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class MantraCard extends StatelessWidget {
  const MantraCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Icon(
                    Icons.spa_outlined,
                    color: AppColors.primaryVariant,
                    size: 24,
                  ),
        ),
        Center(
                    child: Text(
                    'My Achievian Mantra',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  ),
          // Header

          const SizedBox(height: 8),

          // Description
          Text(
            textAlign: TextAlign.center,
            'Achievian Mantra is a powerful daily affirmation that inspires focus, confidence, and determination in every Achievia user preparing for the board exam.',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          // Mantra Text
          Center(
            child: Column(
              children: [
                Text(
                  'I am prepared. I am focused. I am built for this.',
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Every day, I grow closer to my dream.',
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'I will pass — because I am ready.',
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
