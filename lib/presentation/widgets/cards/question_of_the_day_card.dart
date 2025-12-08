// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:achievia/presentation/provider/home/home_provider.dart';

class QuestionOfTheDayCard extends ConsumerWidget {
  final int? selectedIndex;
  const QuestionOfTheDayCard({super.key, 
    this.selectedIndex,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final qotd = ref.watch(qotdProvider);
    final options = qotd.options;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            qotd.question,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(options.length, (index) {
            return RadioListTile<int>(
              value: index,
              groupValue: selectedIndex,
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) {
                if (v != null) {
                  ref.read(qotdProvider.notifier).selectOption(v);
                }
              },
              title: Text(
                options[index],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
