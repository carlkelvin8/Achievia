class TaskEntity {
  final String tasksName;
  final String description;
  final DateTime deadline;

  const TaskEntity({
    required this.tasksName,
    required this.description,
    required this.deadline,
  });
}
