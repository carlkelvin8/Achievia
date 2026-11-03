import 'package:achievia/core/utils/auth_error_utils.dart';
import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/domain/entities/api/task/task_api_entity.dart';
import 'package:achievia/presentation/provider/task/task_provider.dart';
import 'package:achievia/presentation/widgets/buttons/back_button_with_label.dart';
import 'package:achievia/presentation/widgets/cards/reminder_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CompletedScreen extends ConsumerWidget {
  const CompletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 90,
        leading: const BackButtonWithLabel(label: 'Tasks'),
        title: Text(
          'Completed',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [],
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
          final completed = tasks.where((t) => t.isDone).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // group by createdAt date
          final Map<String, List<TaskApiEntity>> groups =
              <String, List<TaskApiEntity>>{};
          for (final t in completed) {
            final d = t.createdAt.toLocal();
            final key =
                '${DateFormat('EEE').format(d).toUpperCase()} '
                '${DateFormat('MMMM d, yyyy').format(d)}';
            groups.putIfAbsent(key, () => []).add(t);
          }

          if (groups.isEmpty) {
            return Center(
              child: Text(
                'No completed tasks',
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
                            dueDateLabel: DateFormat(
                              'MMMM d, yyyy',
                            ).format(item.deadline.toLocal()),
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
