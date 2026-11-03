import 'package:achievia/domain/entities/widgets/question_of_the_day_state.dart';

/// Repository capability for resolving the daily question with small pages.
abstract interface class PagedQotdRepository {
  Future<int?> getDailyQuestionId(int subjectId, DateTime now);
}

abstract class QotdRepository {
  /// Live (not soft-deleted) subjects in stable rotation order (created_at,
  /// then id).
  Future<List<QotdSubject>> getSubjects();

  /// Ids of subjects that have at least one live question in a live subtopic.
  /// One small query; it never downloads questions or choices.
  Future<Set<int>> getSubjectIdsWithQuestions();

  /// Ids of the live questions of [subjectId] in ascending order (ids only).
  Future<List<int>> getLiveQuestionIds(int subjectId);

  /// The subset of [ids] that is eligible for the Question of the Day: not
  /// soft-deleted, with at least two live choices and exactly one correct.
  Future<Set<int>> filterEligibleQuestionIds(List<int> ids);

  /// Full question payload (text, rationale, ordered choices) for [questionId].
  Future<QotdDailyQuestion> getQuestion(int questionId);

  /// The user's answer for [questionId] within the given UTC day window, or
  /// null when the current cycle has not been answered yet.
  Future<QotdUserAnswer?> getTodaysAnswer({
    required int questionId,
    required DateTime dayStartUtc,
    required DateTime dayEndUtc,
  });

  /// Persists the user's answer for the current cycle.
  Future<void> submitAnswer({
    required String userId,
    required int questionId,
    required int quizId,
    required int choiceId,
    required bool isCorrect,
  });
}
