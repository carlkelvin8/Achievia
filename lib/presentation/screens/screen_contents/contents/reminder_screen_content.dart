import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/provider/task/task_provider.dart';
import 'package:achievia/presentation/widgets/buttons/back_button_with_label.dart';
import 'package:achievia/presentation/widgets/cards/reminder_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ReminderScreenContent extends ConsumerStatefulWidget {
  const ReminderScreenContent({super.key});

  @override
  ConsumerState<ReminderScreenContent> createState() =>
      _ReminderScreenContentState();
}

class _ReminderScreenContentState extends ConsumerState<ReminderScreenContent> {
  final Set<int> _selectedIds = {};
  bool _isConfirming = false;

  Future<void> _confirmDone() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Done'),
        content: Text(
          'Mark ${_selectedIds.length} reminder${_selectedIds.length > 1 ? 's' : ''} as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isConfirming = true);
    final notifier = ref.read(markTaskDoneProvider.notifier);
    for (final id in _selectedIds.toList()) {
      await notifier.markDone(id);
    }
    setState(() {
      _selectedIds.clear();
      _isConfirming = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(tasksProvider);
    final bool hasSelection = _selectedIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 90,
        leading: const BackButtonWithLabel(label: 'Tasks'),
        title: Text(
          'Reminders',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isConfirming)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (hasSelection)
            IconButton(
              icon: Icon(Icons.check_circle, color: theme.colorScheme.primary),
              tooltip: 'Mark as done',
              onPressed: _confirmDone,
            )
          else
            IconButton(
              icon: Icon(Icons.more_vert, color: theme.colorScheme.primary),
              onPressed: () {},
            ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: TextStyle(color: theme.colorScheme.error)),
        ),
        data: (tasks) {
          final reminders = tasks.where((t) => !t.isDone).toList()
            ..sort((a, b) => a.deadline.compareTo(b.deadline));

          return SingleChildScrollView(
            child: Padding(
              padding: level2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Achievian Goal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (reminders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(
                          'No reminders',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reminders.length,
                      itemBuilder: (context, index) {
                        final item = reminders[index];
                        final isSelected = _selectedIds.contains(item.id);
                        return ReminderCard(
                          title: item.taskName,
                          subtitle: item.description,
                          dueDateLabel: DateFormat('MMMM d, yyyy')
                              .format(item.deadline.toLocal()),
                          isCompleted: isSelected,
                          onStatusChanged: (_) {
                            setState(() {
                              if (isSelected) {
                                _selectedIds.remove(item.id);
                              } else {
                                _selectedIds.add(item.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

