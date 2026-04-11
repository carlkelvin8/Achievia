class ProgressDayEntity {
  final int id;
  final int userId;
  final DateTime activityDate;
  final bool isActive;

  ProgressDayEntity({
    required this.id,
    required this.userId,
    required this.activityDate,
    required this.isActive,
  });
}
