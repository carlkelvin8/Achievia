// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/data/data_source/home/questions_remote_datasource.dart';
import 'package:achievia/domain/entities/widgets/question_of_the_day_state.dart';
import 'package:achievia/domain/repository/questions/qotd_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
@injectable
class QotRepositoryImpl implements QotdRepository, PagedQotdRepository {
  final QuestionsRemoteDatasource remoteDatasource;

  QotRepositoryImpl({required this.remoteDatasource});

  @override
  Future<int?> getDailyQuestionId(int subjectId, DateTime now) =>
      remoteDatasource.getDailyQuestionId(subjectId, now);

  @override
  Future<List<QotdSubject>> getSubjects() async {
    try {
      return await remoteDatasource.getSubjects();
    } catch (e, st) {
      debugPrint('QotRepository.getSubjects error: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  @override
  Future<Set<int>> getSubjectIdsWithQuestions() async {
    try {
      return await remoteDatasource.getSubjectIdsWithQuestions();
    } catch (e, st) {
      debugPrint('QotRepository.getSubjectIdsWithQuestions error: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  @override
  Future<List<int>> getLiveQuestionIds(int subjectId) async {
    try {
      return await remoteDatasource.getLiveQuestionIds(subjectId);
    } catch (e, st) {
      debugPrint('QotRepository.getLiveQuestionIds error: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  @override
  Future<Set<int>> filterEligibleQuestionIds(List<int> ids) async {
    try {
      return await remoteDatasource.filterEligibleQuestionIds(ids);
    } catch (e, st) {
      debugPrint('QotRepository.filterEligibleQuestionIds error: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  @override
  Future<QotdDailyQuestion> getQuestion(int questionId) async {
    try {
      return await remoteDatasource.getQuestion(questionId);
    } catch (e, st) {
      debugPrint('QotRepository.getQuestion error: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  @override
  Future<QotdUserAnswer?> getTodaysAnswer({
    required int questionId,
    required DateTime dayStartUtc,
    required DateTime dayEndUtc,
  }) async {
    try {
      return await remoteDatasource.getTodaysAnswer(
        questionId: questionId,
        dayStartUtc: dayStartUtc,
        dayEndUtc: dayEndUtc,
      );
    } catch (e, st) {
      debugPrint('QotRepository.getTodaysAnswer error: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  @override
  Future<void> submitAnswer({
    required String userId,
    required int questionId,
    required int quizId,
    required int choiceId,
    required bool isCorrect,
  }) async {
    try {
      await remoteDatasource.submitAnswer(
        userId: userId,
        questionId: questionId,
        quizId: quizId,
        choiceId: choiceId,
        isCorrect: isCorrect,
      );
    } catch (e, st) {
      debugPrint('QotRepository.submitAnswer error: $e');
      debugPrint('$st');
      rethrow;
    }
  }
}
