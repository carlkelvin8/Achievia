import 'dart:math';

import 'package:achievia/data/data_source/reviewer/question_bank_remote_datasource.dart';
import 'package:achievia/domain/entities/api/reviewer/exam_summary_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/repository/questions/question_bank_repository.dart';

class QuestionBankRepositoryImpl implements QuestionBankRepository {
  final QuestionBankDataSource dataSource;

  const QuestionBankRepositoryImpl(this.dataSource);

  @override
  Future<List<QuestionBankSubject>> getAllSubjects() =>
      dataSource.getAllSubjects();

  @override
  Future<List<QuestionBankSubject>> getSubjectsForCourse(int courseId) =>
      dataSource.getSubjectsForCourse(courseId);

  @override
  Future<List<QuestionBankTopic>> getTopics(int subjectId) =>
      dataSource.getTopics(subjectId);

  @override
  Future<List<QuestionItemEntity>> getPracticeQuestions(
    int quizId, {
    int limit = 20,
    Random? random,
  }) => dataSource.getPracticeQuestions(quizId, limit: limit, random: random);

  @override
  Future<List<QuestionItemEntity>> getSubjectExamQuestions(
    int subjectId, {
    int count = 100,
    Random? random,
  }) => dataSource.getSubjectExamQuestions(
    subjectId,
    count: count,
    random: random,
  );

  @override
  Future<QuestionBankAttempt> saveAttempt({
    required QuestionBankSelection selection,
    required int correctAnswers,
    required int totalQuestions,
    ExamAttemptSnapshot? snapshot,
  }) => dataSource.saveAttempt(
    selection: selection,
    correctAnswers: correctAnswers,
    totalQuestions: totalQuestions,
    snapshot: snapshot,
  );

  @override
  Future<ExamAttemptSummary> getExamSummary(String attemptId) =>
      dataSource.getExamSummary(attemptId);

  @override
  Future<List<QuestionBankAttempt>> getRecentAttempts({
    int limit = 5,
    String? attemptType,
  }) => dataSource.getRecentAttempts(limit: limit, attemptType: attemptType);
}
