import 'package:achievia/domain/entities/api/task/task_api_entity.dart';
import 'package:achievia/domain/entities/api/task/task_entity.dart';

abstract class TaskRepository {
  Future<void> createTask(TaskEntity entity);
  Future<List<TaskApiEntity>> getTasks();
  Future<void> markTaskDone(int id);
}
