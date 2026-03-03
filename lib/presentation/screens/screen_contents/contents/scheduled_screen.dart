import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/domain/entities/api/task/task_api_entity.dart';
import 'package:achievia/presentation/provider/task/task_provider.dart';
import 'package:achievia/presentation/widgets/buttons/back_button_with_label.dart';
import 'package:achievia/presentation/widgets/cards/reminder_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ScheduledScreen extends ConsumerWidget {
  const ScheduledScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 90,
        leading: const BackButtonWithLabel(label: 'Tasks'),
        title: Text(
          'Scheduled',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: TextStyle(color: theme.colorScheme.error)),
        ),
        data: (tasks) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          // future non-done tasks
          final scheduled = tasks.where((t) {
            final d = t.deadline.toLocal();
            return !t.isDone &&
                DateTime(d.year, d.month, d.day).isAfter(today);
          }).toList()
            ..sort((a, b) => a.deadline.compareTo(b.deadline));

          // group by deadline date
          final Map<String, List<TaskApiEntity>> groups =
              <String, List<TaskApiEntity>>{};
          for (final t in scheduled) {
            final key =
                '${DateFormat('EEE').format(t.deadline.toLocal()).toUpperCase()} '
                '${DateFormat('MMMM d, yyyy').format(t.deadline.toLocal())}';
            groups.putIfAbsent(key, () => []).add(t);
          }

          if (groups.isEmpty) {
            return Center(
              child: Text(
                'No scheduled tasks',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: level2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: groups.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          entry.key,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: entry.value.length,
                        itemBuilder: (context, index) {
                          final item = entry.value[index];
                          return ReminderCard(
                            title: item.taskName,
                            subtitle: item.description,
                            dueDateLabel: DateFormat('MMMM d, yyyy')
                                .format(item.deadline.toLocal()),
                            isCompleted: item.isDone,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
