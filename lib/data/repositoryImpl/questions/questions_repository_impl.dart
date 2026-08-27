import 'package:achievia/data/data_source/home/questions_remote_datasource.dart';
import 'package:achievia/data/models/quiz/mockboards_paused_dto.dart';
import 'package:achievia/domain/entities/api/home/mockboard_paused_entity.dart';
import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/domain/entities/api/home/results_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/entities/widgets/examination_results_entity.dart';
import 'package:achievia/domain/repository/questions/questions_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
@injectable
class QuestionsRepositoryImpl implements QuestionsRepository {
  final QuestionsRemoteDatasource remoteDatasource;

  QuestionsRepositoryImpl(this.remoteDatasource);
  @override
  Future<List<QuestionsEntity>> getAllQuestions() async {
    try {
      final remoteQuestions = await remoteDatasource.getAllQuestions();
      return remoteQuestions.map((e) => e.toEntity()).toList();
    } catch (e, st) {
      print('Repository error: $e');
      print('Repository stacktrace: $st');
      rethrow;
    }
  }

  @override
  Future<List<QuestionsEntity>> generateQuestions(int index) async {
    try {
      final response = await remoteDatasource.randomizeQuestion(index);
      return response.map((e) => e.toEntity()).toList();
    } catch (e) {
      print('repo q: $e');
      return [];
    }
  }

  @override
  Future<List<QuizItemEntity>> getRandomizedQuestions() async {
    try {
      final response = await remoteDatasource.getTheGeneratedQuiz();
      return response.map((e) => e.toEntity()).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  @override
  Future<QuizScoreEntity?> getQuizScores(int noOfAttempt) async {
    final response = await remoteDatasource.getResults(noOfAttempt);
    print('from impl repo: $noOfAttempt');
    return response.toEntity();
  }

  @override
  Future<int> submitQuiz() async {
    try {
      final response = await remoteDatasource.putToAttempt();
      print('from impl:$response');
      return response;
    } catch (e) {
      print(e);
      return 0;
    }
  }

  @override
  Future<MockboardPausedEntity> continueQuizRepository(
    MockboardPausedEntity entity,
  ) async {
    try {
      final dto = MockboardsPausedDto.fromEntity(entity);
      final data = await remoteDatasource.upsertPaused(dto);
      return data.toEntity();
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  @override
  Future<MockboardPausedEntity> continuegetQuizRepository(
    MockboardPausedEntity entity,
  ) async {
    try {
      final dto = MockboardsPausedDto.fromEntity(entity);
      final data = await remoteDatasource.getCurrentPaused(dto);
      return data.toEntity();
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<ExaminationResult>> getRecentAttemptResults() =>
      remoteDatasource.getRecentAttemptResults();
}
