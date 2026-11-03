import 'dart:math';

import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';

abstract class QuestionBankRepository {
  Future<List<QuestionBankSubject>> getAllSubjects();

  Future<List<QuestionBankSubject>> getSubjectsForCourse(int courseId);

  Future<List<QuestionBankTopic>> getTopics(int subjectId);

  Future<List<QuestionItemEntity>> getPracticeQuestions(
    int quizId, {
    int limit = 20,
    Random? random,
  });

  Future<List<QuestionItemEntity>> getSubjectExamQuestions(
    int subjectId, {
    int count = 100,
    Random? random,
  });

  Future<QuestionBankAttempt> saveAttempt({
    required QuestionBankSelection selection,
    required int correctAnswers,
    required int totalQuestions,
    ExamAttemptSnapshot? snapshot,
  });

  /// Loads the persisted, immutable summary of one completed subject exam by
  /// its attempt id. Throws [ExamSummaryException] when it does not exist, was
  /// never persisted (legacy attempt) or is inconsistent.
  Future<ExamAttemptSummary> getExamSummary(String attemptId);

  /// Newest completed attempts. When [attemptType] is given the filter is
  /// applied before ordering and limiting, so unrelated types cannot use up
  /// the [limit].
  Future<List<QuestionBankAttempt>> getRecentAttempts({
    int limit = 5,
    String? attemptType,
  });
}
