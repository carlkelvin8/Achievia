// Domain layer entity
class QuizScoreEntity {
  final bool success;
  final ScoreEntity score;

  QuizScoreEntity({required this.success, required this.score});
}

class ScoreEntity {
  final String score;
  final List<AnswerEntity> answers;
  final bool passed;
  final double failedWeight;
  final bool hasMajorBelow50;
  final List<String> reasons;

  ScoreEntity({
    required this.score,
    required this.answers,
    required this.passed,
    required this.failedWeight,
    required this.hasMajorBelow50,
    required this.reasons,
  });
}

class AnswerEntity {
  final bool isCorrect;
  final String name;
  final double score;

  AnswerEntity({
    required this.isCorrect,
    required this.name,
    required this.score,
  });
}
