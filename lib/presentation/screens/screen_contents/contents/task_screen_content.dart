import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/domain/entities/widgets/goal_entity.dart';
import 'package:achievia/presentation/provider/home/home_provider.dart';
import 'package:achievia/presentation/provider/task/task_provider.dart';
import 'package:achievia/presentation/widgets/grids/grid_cards.dart';
import 'package:achievia/presentation/widgets/list_items/list_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TaskScreenContent extends ConsumerStatefulWidget {
  const TaskScreenContent({super.key});

  @override
  ConsumerState<TaskScreenContent> createState() => _TaskScreenContentState();
}

/// What the goal dialog returned: a title to save, or [clear] to remove it.
class _GoalEdit {
  const _GoalEdit.save(String this.title, this.details);
  const _GoalEdit.clear() : title = null, details = '';

  final String? title;
  final String details;
}

/// Owns its text controllers so they outlive the dialog's exit animation.
class _GoalDialog extends StatefulWidget {
  const _GoalDialog({required this.goal});

  final GoalEntity? goal;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late final _titleController = TextEditingController(
    text: widget.goal?.title ?? '',
  );
  late final _detailsController = TextEditingController(
    text: widget.goal?.details ?? '',
  );

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(
      context,
      _GoalEdit.save(title, _detailsController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    );
    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    );
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Today's Goal",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                  iconSize: 18,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Goal',
                      border: fieldBorder,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _detailsController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Details',
                      border: fieldBorder,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (widget.goal != null) ...[
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.pop(context, const _GoalEdit.clear()),
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.surfaceContainerHighest,
                              foregroundColor: scheme.onSurface,
                              shape: buttonShape,
                            ),
                            child: const Text('Clear goal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: FilledButton(
                          onPressed: _save,
                          style: FilledButton.styleFrom(shape: buttonShape),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskScreenContentState extends ConsumerState<TaskScreenContent> {
  Future<void> _editGoal(GoalEntity? goal) async {
    final result = await showDialog<_GoalEdit>(
      context: context,
      builder: (_) => _GoalDialog(goal: goal),
    );
    if (result == null || !mounted) return;
    final notifier = ref.read(goalProvider.notifier);
    final ok = result.title == null
        ? await notifier.clearGoal()
        : await notifier.saveTodayGoal(result.title!, result.details);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update your goal.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = ref.watch(goalProvider).value;
    final tasksAsync = ref.watch(tasksProvider);
    final remindersCount =
        tasksAsync
            .whenData((tasks) => tasks.where((t) => !t.isDone).length)
            .value ??
        0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: level2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridCards(),
              SizedBox(height: 20),
              Text(
                'My Achievian Goal',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10),
              ListItemCard(
                icon: Icons.flag_outlined,
                label: "Today's Goal",
                trailingText: goal == null ? 'Not set' : 'Edit',
                margin: const EdgeInsets.only(bottom: 10),
                onTap: () => _editGoal(goal),
              ),
              ListItemCard(
                icon: Icons.list_alt,
                label: 'Reminders',
                trailingText: '$remindersCount',
                onTap: () {
                  context.push(RouteConstants.reminder);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
