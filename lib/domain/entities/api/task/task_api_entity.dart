class TaskApiEntity {
  final int id;
  final String taskName;
  final String description;
  final String userId;
  final bool isDone;
  final DateTime deadline;
  final DateTime createdAt;

  const TaskApiEntity({
    required this.id,
    required this.taskName,
    required this.description,
    required this.userId,
    required this.isDone,
    required this.deadline,
    required this.createdAt,
  });
}
