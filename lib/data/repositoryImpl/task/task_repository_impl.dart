import 'package:achievia/data/data_source/task/task_remote_datasource.dart';
import 'package:achievia/data/models/task/task_dto.dart';
import 'package:achievia/domain/entities/api/task/task_api_entity.dart';
import 'package:achievia/domain/entities/api/task/task_entity.dart';
import 'package:achievia/domain/repository/task/task_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
@injectable
class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDatasource datasource;

  TaskRepositoryImpl(this.datasource);

  @override
  Future<void> createTask(TaskEntity entity) async {
    final dto = TaskDto.fromEntity(entity);
    await datasource.createTask(dto);
  }

  @override
  Future<List<TaskApiEntity>> getTasks() async {
    final dtos = await datasource.getTasks();
    return dtos.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> markTaskDone(int id) => datasource.markTaskDone(id);
}
