import 'package:achievia/domain/entities/api/task/task_entity.dart';

class TaskDto {
  final String tasksName;
  final String description;
  final String deadline;

  TaskDto({
    required this.tasksName,
    required this.description,
    required this.deadline,
  });

  Map<String, dynamic> toJson() => {
        'task_name': tasksName,
        'description': description,
        'deadline': deadline,
      };

  factory TaskDto.fromEntity(TaskEntity entity) => TaskDto(
        tasksName: entity.tasksName,
        description: entity.description,
        deadline: entity.deadline.toUtc().toIso8601String(),
      );
}
