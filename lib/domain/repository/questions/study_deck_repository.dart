import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';

/// Eligible questions for Study Mode. Kept apart from the exam repositories so
/// Study Mode never shares code paths with Take an Exam.
abstract class StudyDeckRepository {
  /// Every eligible question of the subtopic [quizId], canonical order, with
  /// its stored rationale (empty when none).
  Future<List<QuestionItemEntity>> getStudyQuestions(int quizId);
}
