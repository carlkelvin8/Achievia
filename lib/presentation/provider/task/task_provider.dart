import 'dart:async';

import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/entities/api/task/task_api_entity.dart';
import 'package:achievia/domain/entities/api/task/task_entity.dart';
import 'package:achievia/domain/use_cases/task/task_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/provider/task/local_day_provider.dart';
import 'package:achievia/presentation/provider/auth/event/token_state_provider.dart';

final taskUseCaseProvider = Provider<TaskUseCase>((ref) => sl<TaskUseCase>());

// Fetches all tasks from the API
// A failure is shown right away with an explicit Retry button instead of being
// retried silently for minutes behind a "Loading" label.
final tasksProvider = FutureProvider.autoDispose<List<TaskApiEntity>>((
  ref,
) async {
  final token = await ref.watch(tokenStream.future);
  if (token == null) return [];
  return ref.read(taskUseCaseProvider).getTasks();
}, retry: (_, _) => null);

/// Unfinished reminders due on the device's current local calendar day.
final todayTasksProvider =
    Provider.autoDispose<AsyncValue<List<TaskApiEntity>>>((ref) {
      final today = ref.watch(localDayProvider);
      return ref.watch(tasksProvider).whenData((tasks) {
        return tasks.where((t) {
          if (t.isDone) return false;
          return _isSameDay(t.deadline.toLocal(), today);
        }).toList()..sort((a, b) => a.deadline.compareTo(b.deadline));
      });
    });

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

final createTaskProvider = AsyncNotifierProvider<CreateTaskNotifier, void>(
  CreateTaskNotifier.new,
);

class CreateTaskNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> createTask(TaskEntity entity) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(taskUseCaseProvider).createTask(entity),
    );
    state = result;
    if (result is AsyncData) {
      // Invalidate so task lists refresh after creation
      ref.invalidate(tasksProvider);
    }
    return result is AsyncData;
  }
}

final markTaskDoneProvider = AsyncNotifierProvider<MarkTaskDoneNotifier, void>(
  MarkTaskDoneNotifier.new,
);

class MarkTaskDoneNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> markDone(String id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(taskUseCaseProvider).markTaskDone(id),
    );
    state = result;
    if (result is AsyncData) {
      ref.invalidate(tasksProvider);
    }
    return result is AsyncData;
  }
}
