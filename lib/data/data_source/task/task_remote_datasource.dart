import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/di/local_storage_service.dart';
import 'package:achievia/data/models/task/task_dto.dart';
import 'package:achievia/data/models/task/task_read_dto.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

abstract class TaskDataSource {
  Future<void> createTask(TaskDto dto);
  Future<List<TaskReadDto>> getTasks();
  Future<void> markTaskDone(int id);
}

@lazySingleton
@injectable
class TaskRemoteDatasource implements TaskDataSource {
  final Dio dio;

  TaskRemoteDatasource(this.dio);

  @override
  Future<void> createTask(TaskDto dto) async {
    final LocalStorageService storageService = sl<LocalStorageService>();
    final token = storageService.token;
    try {
      final response = await dio.post(
        '/tasks/create',
        data: dto.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: response.data['message'] ?? 'Failed to create task',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<TaskReadDto>> getTasks() async {
    final LocalStorageService storageService = sl<LocalStorageService>();
    final token = storageService.token;
    try {
      final response = await dio.get(
        '/tasks/read',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      final List<dynamic> raw =
          response.data['data']['data'] as List<dynamic>;
      return raw
          .map((e) => TaskReadDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> markTaskDone(int id) async {
    final LocalStorageService storageService = sl<LocalStorageService>();
    final token = storageService.token;
    try {
      await dio.put(
        '/tasks/update/$id',

        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } catch (e) {
      rethrow;
    }
  }
}
