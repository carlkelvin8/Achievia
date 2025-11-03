class ReminderEntity {
  final String title;
  final String? subtitle;
  final String dueDateLabel;
  final double progress; // 0.0 - 1.0

  const ReminderEntity({
    required this.title,
    this.subtitle,
    required this.dueDateLabel,
    required this.progress,
  });
}

