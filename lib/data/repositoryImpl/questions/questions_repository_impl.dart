import 'package:achievia/core/network/conntectivity.dart';
import 'package:achievia/core/network/offline_caching.dart';
import 'package:achievia/data/data_source/home/questions_remote_datasource.dart';
import 'package:achievia/data/models/quiz/mockboards_paused_dto.dart';
import 'package:achievia/domain/entities/api/home/mockboard_paused_entity.dart';
import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/domain/entities/api/home/results_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/repository/questions/questions_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
@injectable
class QuestionsRepositoryImpl implements QuestionsRepository {
  final QuestionsRemoteDatasource remoteDatasource;
  final NetworkInfo network;
  final OfflineCaching local;

  QuestionsRepositoryImpl(this.remoteDatasource, this.network, this.local);
  @override
  Future<List<QuestionsEntity>> getAllQuestions() async {
    try {
      final connectivity = await network.isConnected;
      if (connectivity) {
        final remoteQuestions = await remoteDatasource.getAllQuestions();
        print('Repository - Remote questions received: $remoteQuestions');
        await local.insertQuestionsToCache(remoteQuestions);
        final mapped = remoteQuestions.map((e) => e.toEntity()).toList();
        print('Repository - Mapped to entities: $mapped');
        return mapped;
      } else {
        final cached = await local.getQuestionsFromCache();
        return cached.map((e) => e.toEntity()).toList();
      }
    } catch (e, st) {
      print('Repository error: $e');
      print('Repository stacktrace: $st');
      rethrow;
    }
  }

  @override
  Future<List<QuestionsEntity>> generateQuestions(int index) async {
    final isConnected = await network.isConnected;
    try {
      if (isConnected) {
        final response = await remoteDatasource.randomizeQuestion(index);
        print('REPO${response.map((e) => e.toEntity()).toList()}');
        final mapped = response.map((e) => e.toEntity()).toList();
        return mapped;
      }
      return [];
    } catch (e) {
      print('repo q: $e');
      return [];
    }
  }

  @override
  Future<List<QuizItemEntity>> getRandomizedQuestions() async {
    final isConnected = await network.isConnected;
    try {
      if (isConnected) {
        final responseCached = await remoteDatasource.getTheGeneratedQuiz();
        final mapData = responseCached.map((e) => e.toEntity()).toList();
        return mapData;
      }
      return [];
    } catch (e) {
      print(e);
      return [];
    }
  }

  @override
  Future<QuizScoreEntity?> getQuizScores(int noOfAttempt) async {
    final responseCached = await remoteDatasource.getResults(noOfAttempt);
    print('from impl repo: $noOfAttempt');
    return responseCached.toEntity();
  }

  @override
  Future<int> submitQuiz() async {
    try {
      final responseCached = await remoteDatasource.putToAttempt();
      print('from impl:$responseCached');
      return responseCached;
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
}
