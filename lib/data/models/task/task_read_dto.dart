import 'package:achievia/domain/entities/api/task/task_api_entity.dart';

class TaskReadDto {
  final String id;
  final String taskName;
  final String description;
  final String userId;
  final bool isDone;
  final DateTime deadline;
  final DateTime createdAt;

  TaskReadDto({
    required this.id,
    required this.taskName,
    required this.description,
    required this.userId,
    required this.isDone,
    required this.deadline,
    required this.createdAt,
  });

  factory TaskReadDto.fromJson(Map<String, dynamic> json) => TaskReadDto(
        id: json['id'] as String,
        taskName: json['task_name'] as String,
        description: json['description'] as String,
        userId: json['user_id'] as String,
        isDone: json['is_done'] as bool,
        deadline: DateTime.parse(json['deadline'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  TaskApiEntity toEntity() => TaskApiEntity(
        id: id,
        taskName: taskName,
        description: description,
        userId: userId,
        isDone: isDone,
        deadline: deadline,
        createdAt: createdAt,
      );
}
