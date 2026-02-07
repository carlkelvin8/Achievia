import 'package:achievia/core/network/conntectivity.dart';

import 'package:achievia/data/data_source/home/questions_remote_datasource.dart';
import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/domain/entities/api/home/results_entity.dart';
import 'package:achievia/domain/repository/questions/questions_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
@injectable
class QuestionsRepositoryImpl implements QuestionsRepository {
  final QuestionsRemoteDatasource remoteDatasource;
  final NetworkInfo network;

  QuestionsRepositoryImpl(this.remoteDatasource, this.network);
  @override
  Future<List<QuestionsEntity>> getAllQuestions(String token, String id) async {
    try {
      final connectivity = await network.isConnected;
      if (connectivity) {
        final remoteQuestions = await remoteDatasource.getAllQuestions(
          token,
          id,
        );
        print('Repository - Remote questions received: $remoteQuestions');
        final mapped = remoteQuestions.map((e) => e.toEntity()).toList();
        print('Repository - Mapped to entities: $mapped');
        return mapped;
      } else {
        return [];
      }
    } catch (e, st) {
      print('Repository error: $e');
      print('Repository stacktrace: $st');
      rethrow;
    }
  }

  @override
  Future<List<QuestionsEntity>> generateQuestions() async {
    final isConnected = await network.isConnected;
    try {
      if (isConnected) {
        final response = await remoteDatasource.randomizeQuestion();
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
  Future<List<QotyEntity>> getRandomizedQuestions() async {
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
  Future<QuizScoreEntity?> getQuizScores() async {
    final isConnected = await network.isConnected;
    try {
      if (isConnected) {
        final responseCached = await remoteDatasource.getResults();
        return responseCached.toEntity();
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
