class ReminderEntity {
  final String title;
  final String? subtitle;
  final String dueDateLabel;
  final bool isCompleted;

  const ReminderEntity({
    required this.title,
    this.subtitle,
    required this.dueDateLabel,
    this.isCompleted = false,
  });

  ReminderEntity copyWith({
    String? title,
    String? subtitle,
    String? dueDateLabel,
    bool? isCompleted,
  }) {
    return ReminderEntity(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      dueDateLabel: dueDateLabel ?? this.dueDateLabel,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
