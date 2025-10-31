import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/constants/widget_paddings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/domain/entities/progress_entity.dart';
import 'package:achievia/core/utils/helpers.dart';

class ProgressScreenContent extends ConsumerWidget {
  const ProgressScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final items =
        demoProgressItems; // Replace with provider-backed list when ready

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: level2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Achievian Goal',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              ...items.map((e) => _ProgressCard(item: e)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ProgressEntity item;
  const _ProgressCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: level2_widget,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSecondary,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: _CircleProgress(value: item.progress),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  item.dueDateLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
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

class _CircleProgress extends StatelessWidget {
  final double value;
  const _CircleProgress({required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value.clamp(0.0, 1.0),
            strokeWidth: 3,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
          Container(
            width: 10,
            height: 10,
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

// Demo items moved to helpers.dart: demoProgressItems
