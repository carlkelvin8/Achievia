import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:achievia/data/models/task/task_dto.dart';
import 'package:achievia/data/models/task/task_read_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class TaskDataSource {
  Future<void> createTask(TaskDto dto);
  Future<List<TaskReadDto>> getTasks();
  Future<void> markTaskDone(int id);
}

@lazySingleton
@injectable
class TaskRemoteDatasource implements TaskDataSource {
  final SupabaseUserContext userContext;

  TaskRemoteDatasource({this.userContext = const SupabaseUserContext()});

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<void> createTask(TaskDto dto) async {
    final userId = await userContext.currentUserId();

    await _supabase.from('tasks').insert({
      'task_name': dto.tasksName,
      'description': dto.description,
      'user_id': userId,
      'isDone': false,
      'deadline': dto.deadline,
    });
  }

  @override
  Future<List<TaskReadDto>> getTasks() async {
    final userId = await userContext.currentUserId();
    final rows = await _supabase
        .from('tasks')
        .select(
          'id, task_name, description, user_id, isDone, deadline, created_at',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.map((row) {
      final json = Map<String, dynamic>.from(row);
      json['createdAt'] = json['created_at'] ?? json['createdAt'];
      return TaskReadDto.fromJson(json);
    }).toList();
  }

  @override
  Future<void> markTaskDone(int id) async {
    final userId = await userContext.currentUserId();

    await _supabase
        .from('tasks')
        .update({'isDone': true})
        .eq('id', id)
        .eq('user_id', userId);
  }
}
