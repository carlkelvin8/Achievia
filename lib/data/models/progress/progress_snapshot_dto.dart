import 'package:achievia/data/models/progress/progress_day_dto.dart';

class ProgressSnapshotDto {
  final List<ProgressDayDto> activeDays;
  final List<Map<String, dynamic>> quizAttempts;
  final List<Map<String, dynamic>> studySessions;

  const ProgressSnapshotDto({
    required this.activeDays,
    required this.quizAttempts,
    required this.studySessions,
  });
}
