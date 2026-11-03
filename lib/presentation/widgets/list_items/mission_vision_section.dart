import 'package:achievia/presentation/provider/about/about_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mission, Vision, and Core Values section for the Achievia About tab
class MissionVisionSection extends ConsumerWidget {
  const MissionVisionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expandedState = ref.watch(mvcExpandableItemsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Our Purpose & Principles',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),

        // Mission
        _MvcCard(
          index: 0,
          title: 'Mission',
          icon: Icons.flag_rounded,
          isExpanded: expandedState.expandedItems[0] ?? false,
          onExpandedChanged: (expanded) {
            ref
                .read(mvcExpandableItemsProvider.notifier)
                .setExpanded(0, expanded);
          },
          content:
              'We empower learners to transform challenges into opportunities. Through purposeful, inclusive, and values-driven education, we ignite curiosity, build resilience, and inspire excellence. With innovation and integrity, we rise together.',
        ),
        const SizedBox(height: 8),

        // Vision
        _MvcCard(
          index: 1,
          title: 'Vision',
          icon: Icons.visibility_rounded,
          isExpanded: expandedState.expandedItems[1] ?? false,
          onExpandedChanged: (expanded) {
            ref
                .read(mvcExpandableItemsProvider.notifier)
                .setExpanded(1, expanded);
          },
          content:
              'To become the leading platform for transformative, inclusive learning, where dreams are nurtured, differences are celebrated, and every learner is equipped to succeed with confidence, purpose, and pride.',
        ),
        const SizedBox(height: 8),

        // Core Values
        _MvcCard(
          index: 2,
          title: 'Core Values',
          icon: Icons.diamond_rounded,
          isExpanded: expandedState.expandedItems[2] ?? false,
          onExpandedChanged: (expanded) {
            ref
                .read(mvcExpandableItemsProvider.notifier)
                .setExpanded(2, expanded);
          },
          expandedChild: _CoreValuesList(theme: theme),
        ),
      ],
    );
  }
}

class _MvcCard extends StatelessWidget {
  final int index;
  final String title;
  final IconData icon;
  final bool isExpanded;
  final ValueChanged<bool> onExpandedChanged;
  final String? content;
  final Widget? expandedChild;

  const _MvcCard({
    required this.index,
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.onExpandedChanged,
    this.content,
    this.expandedChild,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => onExpandedChanged(!isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(68, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child:
                    expandedChild ??
                    Text(
                      content ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CoreValuesList extends StatelessWidget {
  final ThemeData theme;

  const _CoreValuesList({required this.theme});

  /// The Achievia core values, each anchored to a letter of the name.
  static const _values = [
    (
      letter: 'A',
      label: 'Aspiration',
      desc:
          'Achie-via aspiration by dreaming boldly, setting meaningful goals, and striving toward your highest potential.',
    ),
    (
      letter: 'C',
      label: 'Commitment',
      desc:
          'Achie-via commitment through consistency, discipline, and dedication, knowing that lasting success is built one step at a time.',
    ),
    (
      letter: 'H',
      label: 'Honesty',
      desc:
          'Achie-via honesty by practicing truthfulness, integrity, and accountability in every action, building trust that supports meaningful growth.',
    ),
    (
      letter: 'I',
      label: 'Innovation',
      desc:
          'Achie-via innovation through creativity, technology, and forward-thinking approaches that make learning more effective, engaging, and relevant.',
    ),
    (
      letter: 'E',
      label: 'Excellence',
      desc:
          'Achie-via excellence by continuously improving, raising standards, and giving your best in every learning experience.',
    ),
    (
      letter: 'V',
      label: 'Values',
      desc:
          'Achie-via values by learning and leading with purpose, respect, responsibility, integrity, and strong principles.',
    ),
    (
      letter: 'I',
      label: 'Inclusivity',
      desc:
          'Achie-via inclusivity by embracing differences, creating equal opportunities, and ensuring every learner feels respected, supported, and empowered.',
    ),
    (
      letter: 'A',
      label: 'Achievement',
      desc:
          'Achie-via achievement by recognizing every step forward, celebrating progress, and turning each milestone into motivation for greater success.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _values
          .map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      v.letter,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          v.desc,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
