import 'dart:convert';

import 'package:achievia/const.dart';
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/di/local_storage_service.dart';
import 'package:achievia/core/network/offline_caching.dart';
import 'package:achievia/data/models/quiz/qotd_dto.dart';
import 'package:achievia/data/models/quiz/qotd_dto_post.dart';
import 'package:achievia/data/models/quiz/questions_dto.dart';
import 'package:achievia/data/models/quiz/results_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

abstract class QuestionRepoDataSource {
  Future<List<QuestionsDto>> getAllQuestions(String token, String id);
  Future<QotdDto> getQotd();
  Future<QotdDtoPost> answerQuestion(QotdDtoPost dto, String token);
  Future<List<QotdDto>> getTheGeneratedQuiz();
  Future<List<QuestionsDto>> randomizeQuestion(int index);
  Future<QuizScoreResponse> getResults(int noOfAttempt);
  Future<int> putToAttempt();
}

@lazySingleton
@injectable
class QuestionsRemoteDatasource implements QuestionRepoDataSource {
  final Dio dio;
  final OfflineCaching local;
  QuestionsRemoteDatasource(this.dio, this.local);
  @override
  Future<List<QuestionsDto>> getAllQuestions(String token, String id) async {
    try {
      final response = await dio.get(
        '$BASE_URL/tasks/getQuiz?id=$id',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'x-user-id': id,
          },
        ),
      );
      final questionData = response.data['data']['response'] as List<dynamic>;

      final questionsList = questionData
          .map((e) => QuestionsDto.fromJson(e))
          .toList();

      return questionsList;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<QotdDto> getQotd() async {
    try {
      final response = await dio.get(
        '$BASE_URL/tasks/get1Question',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final questionMap = Map<String, dynamic>.from(
        response.data['data']['response']['question'],
      );
      final choicesList = List<Map<String, dynamic>>.from(
        response.data['data']['response']['choices'] ?? [],
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final flattened = {
          ...questionMap,
          'title': questionMap['title'] ?? '',
          'choices': choicesList,
        };
        return QotdDto.fromJson(flattened);
      } else {
        return QotdDto.fromJson(await response.data);
      }
    } catch (e) {
      print(e);
      return QotdDto.fromJson({});
    }
  }

  @override
  Future<QotdDtoPost> answerQuestion(QotdDtoPost dto, String token) async {
    try {
      final response = await dio.post(
        '$BASE_URL/tasks/ansQuestion',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: dto.toJson(),
      );
      debugPrint('datasource: ${response.data}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return dto;
      }
      return dto;
    } on DioException catch (e) {
      debugPrint("DioException: ${e.response?.data}");
      return QotdDtoPost.fromJson({});
    } catch (e) {
      debugPrint("Exception: $e");
      return QotdDtoPost.fromJson({});
    }
  }

  @override
  Future<List<QuestionsDto>> randomizeQuestion(int index) async {
    try {
      final response = await dio.post(
        '$BASE_URL/tasks/randomizeQuestions',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = await response.data['data']['response']['subjects'] as List<dynamic>;
        final quizTitles = await response.data['data']['response']['quiz'] as List<dynamic>;
        debugPrint('Quiz Titles: ${quizTitles.map((q) => q['title']).toList()}', wrapWidth: 1024);
        final selectedQuiz = Map<String, dynamic>.from(response.data['data']['response']['quiz'][index] as Map);
        debugPrint('Selected Quiz: ${jsonEncode(selectedQuiz)}', wrapWidth: 1024);
        final list = data.map((e) => QuestionsDto.fromJson(e)).toList();
        await local.insertQuestionsToCache(list);
        await local.insertQotdToCache(quizTitles.map((q) => QotdDto.fromJson(Map<String, dynamic>.from(q))).toList());
        return list;
      }
      return [];
    } on DioException catch (e) {
      debugPrint("DioException: ${e.response?.data}");
      return [];
    } catch (e) {
      debugPrint("Exception: $e");
      return [];
    }
  }

  @override
  Future<List<QotdDto>> getTheGeneratedQuiz() async {
    try {
      final cache = await local.getQotdFromCache();
      return cache;
    } catch (e) {
      print(e);
      return [];
    }
  }

  @override
  Future<QuizScoreResponse> getResults(int noOfAttempt) async {
    print('from quiz: $noOfAttempt');
    try {
      final response = await dio.get(
        '$BASE_URL/tasks/getGWA/$noOfAttempt',
        options: Options(
          contentType: 'application/json',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return QuizScoreResponse.fromJson(response.data);
      }
      return QuizScoreResponse.fromJson({});
    } on DioException catch (e) {
      print(e.response?.data);
      return QuizScoreResponse.fromJson({});
    }
  }

  @override
  Future<int> putToAttempt() async {
    final LocalStorageService storageService = sl<LocalStorageService>();
    try {
      final getId = storageService.creds;
      final response = await dio.post(
        '$BASE_URL/tasks/putToQuizAttempt/$getId',
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('from datasource: ${response.data['data']['attempt']}');
        return response.data['data']['attempt'];
      }
      debugPrint('from datasource: ${response.data['data']['attempt']}');
      return response.data['data']['attempt'];
    } on DioException catch (e) {
      debugPrint("DioException: ${e.response?.data}");
      return e.response?.data['message'];
    } catch (e) {
      debugPrint("Exception: $e");
      return 0;
    }
  }
}
