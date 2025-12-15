import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/widgets/list_items/expandable_item.dart';
import 'package:achievia/presentation/provider/about/about_provider.dart';

/// Logo meaning section with expandable items explaining each aspect
class LogoMeaningSection extends ConsumerWidget {
  const LogoMeaningSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expandedState = ref.watch(expandableItemsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The Meaning Behind the Achievia Logo',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),

        // Expandable Items
        ExpandableItem(
          title: 'Official Logo',
          description:
              'The letter A symbolizes not just our name, but our aim for excellence — to help learners become A+ achievers. It stands tall, representing ambition, aspiration, and the start of a successful academic journey.',
          isExpanded: expandedState.expandedItems[0] ?? false,
          onExpandedChanged: (expanded) {
            ref.read(expandableItemsProvider.notifier).setExpanded(0, expanded);
          },
          imagePath: 'assets/images/logo.png',
        ),
        const SizedBox(height: 8),
        ExpandableItem(
          title: 'Peak',
          description: '',
          isExpanded: expandedState.expandedItems[1] ?? false,
          onExpandedChanged: (expanded) {
            ref.read(expandableItemsProvider.notifier).setExpanded(1, expanded);
          },
          imagePath: 'assets/images/logo.png',
        ),
        const SizedBox(height: 8),
        ExpandableItem(
          title: 'Ups and Downs',
          description: '',
          isExpanded: expandedState.expandedItems[2] ?? false,
          onExpandedChanged: (expanded) {
            ref.read(expandableItemsProvider.notifier).setExpanded(2, expanded);
          },
          imagePath: 'assets/images/logo.png',
        ),
        const SizedBox(height: 8),
        ExpandableItem(
          title: 'Mistakes and Curiosity',
          description: '',
          isExpanded: expandedState.expandedItems[3] ?? false,
          onExpandedChanged: (expanded) {
            ref.read(expandableItemsProvider.notifier).setExpanded(3, expanded);
          },
          imagePath: 'assets/images/logo.png',
        ),
        const SizedBox(height: 8),
        ExpandableItem(
          title: 'Corrections and Improvements',
          description: '',
          isExpanded: expandedState.expandedItems[4] ?? false,
          onExpandedChanged: (expanded) {
            ref.read(expandableItemsProvider.notifier).setExpanded(4, expanded);
          },
          imagePath: 'assets/images/logo.png',
        ),
      ],
    );
  }
}
