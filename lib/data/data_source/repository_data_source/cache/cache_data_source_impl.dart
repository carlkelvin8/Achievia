import 'package:achievia/data/models/quiz/questions_dto.dart';

abstract class CacheRemoteDataSource {
  Future<List<QuestionsDto>> getCacheQuestions();
}