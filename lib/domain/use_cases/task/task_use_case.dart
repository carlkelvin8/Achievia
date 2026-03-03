import 'package:achievia/data/repositoryImpl/task/task_repository_impl.dart';
import 'package:achievia/domain/entities/api/task/task_api_entity.dart';
import 'package:achievia/domain/entities/api/task/task_entity.dart';
import 'package:injectable/injectable.dart';

@injectable
class TaskUseCase {
  final TaskRepositoryImpl repository;

  TaskUseCase(this.repository);

  Future<void> createTask(TaskEntity entity) => repository.createTask(entity);

  Future<List<TaskApiEntity>> getTasks() => repository.getTasks();

  Future<void> markTaskDone(int id) => repository.markTaskDone(id);
}
