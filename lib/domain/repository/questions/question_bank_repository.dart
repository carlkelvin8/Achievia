import 'dart:math';

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

  Future<QuestionBankAttempt> saveAttempt({
    required QuestionBankSelection selection,
    required int correctAnswers,
    required int totalQuestions,
  });

  Future<List<QuestionBankAttempt>> getRecentAttempts({int limit = 5});
}
