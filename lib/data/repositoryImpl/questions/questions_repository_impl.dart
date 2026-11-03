import 'package:achievia/core/utils/mock_board_progress.dart';
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
      debugPrint('QuestionsRepository.getAllQuestions error: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  @override
  Future<List<QuestionsEntity>> generateQuestions(int index) async {
    try {
      final response = await remoteDatasource.randomizeQuestion(index);
      return response.map((e) => e.toEntity()).toList();
    } catch (e, st) {
      debugPrint('QuestionsRepository.generateQuestions error: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  @override
  Future<List<QuizItemEntity>> getRandomizedQuestions() async {
    try {
      final response = await remoteDatasource.getTheGeneratedQuiz();
      return response.map((e) => e.toEntity()).toList();
    } catch (e, st) {
      debugPrint('QuestionsRepository.getRandomizedQuestions error: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  @override
  Future<QuizScoreEntity?> getQuizScores(int noOfAttempt) async {
    final response = await remoteDatasource.getResults(noOfAttempt);
    return response.toEntity();
  }

  @override
  Future<bool> startMockBoardAttempt() =>
      remoteDatasource.startMockBoardAttempt();

  @override
  MockBoardSession? exportMockBoardSession() =>
      remoteDatasource.exportMockBoardSession();

  @override
  void restoreMockBoardSession(MockBoardSession session) =>
      remoteDatasource.restoreMockBoardSession(session);

  @override
  Future<int> submitQuiz() async {
    try {
      final response = await remoteDatasource.putToAttempt();
      return response;
    } catch (e, st) {
      debugPrint('QuestionsRepository.submitQuiz error: $e');
      debugPrint('$st');
      rethrow;
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
    } catch (e, st) {
      debugPrint('QuestionsRepository.continueQuizRepository error: $e');
      debugPrint('$st');
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
    } catch (e, st) {
      debugPrint('QuestionsRepository.continuegetQuizRepository error: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  @override
  Future<List<ExaminationResult>> getRecentAttemptResults() =>
      remoteDatasource.getRecentAttemptResults();
}
