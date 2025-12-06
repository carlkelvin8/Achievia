class GoalEntity {
  final String id;
  final DateTime date;
  final String title;
  final String details; // e.g., pages or extra info
  final bool isChecked;

  const GoalEntity({
    required this.id,
    required this.date,
    required this.title,
    required this.details,
    this.isChecked = false,
  });

  GoalEntity copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? details,
    bool? isChecked,
  }) {
    return GoalEntity(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      details: details ?? this.details,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}
