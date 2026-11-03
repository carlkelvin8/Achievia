import 'package:achievia/core/utils/auth_error_utils.dart';
import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/utils/snack_bar_utils.dart';
import 'package:achievia/presentation/provider/task/task_provider.dart';
import 'package:achievia/presentation/widgets/buttons/back_button_with_label.dart';
import 'package:achievia/presentation/widgets/cards/reminder_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final Set<String> _selectedIds = {};
  bool _isConfirming = false;

  Future<void> _confirmDone() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Done'),
        content: Text(
          'Mark ${_selectedIds.length} task${_selectedIds.length > 1 ? 's' : ''} as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isConfirming = true);
    final notifier = ref.read(markTaskDoneProvider.notifier);
    final failed = <String>{};
    for (final id in _selectedIds.toList()) {
      if (!await notifier.markDone(id)) failed.add(id);
    }
    if (!mounted) return;
    setState(() {
      // Keep failed items selected so the user can retry them.
      _selectedIds
        ..clear()
        ..addAll(failed);
      _isConfirming = false;
    });
    if (failed.isEmpty) {
      AppToast.showSuccess(context, 'Task marked as done!');
    } else {
      AppToast.showError(
        context,
        'Some tasks could not be marked as done. Please try again.',
      );
    }
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
          'Today',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            userFacingError(e),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
        data: (tasks) {
          final now = DateTime.now();
          final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
          final todayTasks = tasks.where((t) {
            if (t.isDone) return false;
            final d = t.deadline.toLocal();
            // Include today and overdue tasks
            return d.isBefore(endOfToday) ||
                (d.year == now.year &&
                    d.month == now.month &&
                    d.day == now.day);
          }).toList()..sort((a, b) => a.deadline.compareTo(b.deadline));

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
                  if (todayTasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(
                          'No tasks due today',
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
                      itemCount: todayTasks.length,
                      itemBuilder: (context, index) {
                        final item = todayTasks[index];
                        final isSelected = _selectedIds.contains(item.id);
                        return ReminderCard(
                          title: item.taskName,
                          subtitle: item.description,
                          dueDateLabel: _formatDate(item.deadline),
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

  String _formatDate(DateTime dt) =>
      DateFormat('MMMM d, yyyy').format(dt.toLocal());
}
