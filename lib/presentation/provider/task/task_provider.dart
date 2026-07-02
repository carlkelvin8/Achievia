import 'dart:async';

import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/entities/api/task/task_api_entity.dart';
import 'package:achievia/domain/entities/api/task/task_entity.dart';
import 'package:achievia/domain/use_cases/task/task_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final taskUseCaseProvider = Provider<TaskUseCase>((ref) => sl<TaskUseCase>());

// Fetches all tasks from the API
final tasksProvider = FutureProvider<List<TaskApiEntity>>((ref) {
  return ref.read(taskUseCaseProvider).getTasks();
});

final createTaskProvider =
    AsyncNotifierProvider<CreateTaskNotifier, void>(CreateTaskNotifier.new);

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

final markTaskDoneProvider =
    AsyncNotifierProvider<MarkTaskDoneNotifier, void>(MarkTaskDoneNotifier.new);

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
