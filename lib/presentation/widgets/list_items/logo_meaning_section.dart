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
          title: 'Peak',
          description:
              'The “A” symbolizes aspiration and ambition. It stands tall as a marker of excellence, beginning every learner’s climb to success.',
          isExpanded: expandedState.expandedItems[0] ?? false,
          onExpandedChanged: (expanded) {
            ref.read(expandableItemsProvider.notifier).setExpanded(0, expanded);
          },
          imagePath: 'assets/images/LOGO/4.svg',
        ),
        const SizedBox(height: 8),
        ExpandableItem(
          title: 'Ups and Downs',
          description:
              'The lines in our logo reflect the real learning journey, full of highs, lows, doubts, and breakthroughs.',
          isExpanded: expandedState.expandedItems[1] ?? false,
          onExpandedChanged: (expanded) {
            ref.read(expandableItemsProvider.notifier).setExpanded(1, expanded);
          },
          imagePath: 'assets/images/LOGO/6.svg',
        ),
        const SizedBox(height: 8),
        ExpandableItem(
          title: 'Mistakes & Curiosity',
          description:
              'The “X” stands for mistakes. Asking “Y” represents curiosity as the spark of deeper learning.',
          isExpanded: expandedState.expandedItems[2] ?? false,
          onExpandedChanged: (expanded) {
            ref.read(expandableItemsProvider.notifier).setExpanded(2, expanded);
          },
          imagePath: 'assets/images/LOGO/7.svg',
        ),
        const SizedBox(height: 8),
        ExpandableItem(
          title: 'Corrections and Improvements',
          description:
              'Our check-like lines represent support and progress because growth comes from reflection and guidance.',
          isExpanded: expandedState.expandedItems[3] ?? false,
          onExpandedChanged: (expanded) {
            ref.read(expandableItemsProvider.notifier).setExpanded(3, expanded);
          },
          imagePath: 'assets/images/LOGO/8.svg',
        ),
        const SizedBox(height: 8),
        ExpandableItem(
          title: 'Rest & Wellness',
          description:
              'The intentional spaces in the logo stand for mental wellness. Rest isn’t a pause in learning. It’s part of it.',
          isExpanded: expandedState.expandedItems[4] ?? false,
          onExpandedChanged: (expanded) {
            ref.read(expandableItemsProvider.notifier).setExpanded(4, expanded);
          },
          imagePath: 'assets/images/LOGO/Logo2_1.svg',
        ),
      ],
    );
  }
}
