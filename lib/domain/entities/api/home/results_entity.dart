// Domain layer entity
class QuizScoreEntity {
  final bool success;
  final ScoreEntity score;

  QuizScoreEntity({required this.success, required this.score});
}

class ScoreEntity {
  final String score;
  final List<AnswerEntity> answers;

  ScoreEntity({required this.score, required this.answers});
}

class AnswerEntity {
  final bool isCorrect;
  final String name;
  final double score;

  AnswerEntity({required this.isCorrect, required this.name, required this.score});
}
