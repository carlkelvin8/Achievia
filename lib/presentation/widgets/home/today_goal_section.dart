import 'package:achievia/core/utils/auth_error_utils.dart';
import 'package:achievia/core/utils/formatters.dart';
import 'package:achievia/presentation/provider/home/home_provider.dart';
import 'package:achievia/presentation/provider/task/task_provider.dart';
import 'package:achievia/presentation/widgets/cards/goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reminders remain visible independently of the optional dedicated goal.
class TodayGoalSection extends ConsumerWidget {
  const TodayGoalSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(todayTasksProvider);
    final goal = ref.watch(goalProvider).value;
    final busy = ref.watch(markTaskDoneProvider).isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (goal != null) ...[
          GoalCard(
            date: Formatters().formatDate(goal.date.toLocal()),
            title: goal.title,
            details: goal.details,
            isChecked: goal.isChecked,
            onToggle: () => ref.read(goalProvider.notifier).toggleChecked(),
            allowUncheck: true,
          ),
          const SizedBox(height: 8),
        ],
        tasks.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text('Loading reminders...')),
          ),
          error: (error, _) {
            // The real cause goes to the log only; users get a safe message.
            debugPrint(
              'Reminders failed to load: ${error.runtimeType}: $error',
            );
            return TextButton.icon(
              onPressed: () => ref.invalidate(tasksProvider),
              icon: const Icon(Icons.refresh),
              label: Text(
                isNetworkError(error)
                    ? '$networkErrorMessage Retry'
                    : 'Unable to load reminders. Retry',
                textAlign: TextAlign.center,
              ),
            );
          },
          data: (items) {
            if (items.isEmpty) {
              return goal != null
                  ? const SizedBox.shrink()
                  : const _NoGoalCard();
            }
            return Column(
              children: [
                for (final task in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GoalCard(
                      date: Formatters().formatDate(task.deadline.toLocal()),
                      title: task.taskName,
                      details: task.description,
                      isChecked: task.isDone,
                      onToggle: busy
                          ? null
                          : () async {
                              final success = await ref
                                  .read(markTaskDoneProvider.notifier)
                                  .markDone(task.id);
                              if (!success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Unable to complete reminder. Please try again.',
                                    ),
                                  ),
                                );
                              }
                            },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// The Daily Goal box when nothing is set for today: it keeps its place and
/// the goal card's look, so clearing a goal never makes the box disappear.
class _NoGoalCard extends StatelessWidget {
  const _NoGoalCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('no-goal-card'),
      constraints: const BoxConstraints(minHeight: 96),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        'No goal set for today',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
