import 'package:achievia/data/models/progress/progress_day_dto.dart';

class ProgressSnapshotDto {
  final List<ProgressDayDto> activeDays;
  final List<Map<String, dynamic>> quizAttempts;
  final List<Map<String, dynamic>> studySessions;

  /// Raw `question_bank_attempts` rows (individual subject exams) used for
  /// Best / Weakest Subject. Kept apart from [quizAttempts], which also
  /// contains Mock Board attempts.
  final List<Map<String, dynamic>> subjectExamAttempts;

  const ProgressSnapshotDto({
    required this.activeDays,
    required this.quizAttempts,
    required this.studySessions,
    this.subjectExamAttempts = const [],
  });
}
