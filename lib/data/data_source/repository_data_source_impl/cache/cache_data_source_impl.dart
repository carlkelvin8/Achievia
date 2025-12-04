import 'package:achievia/data/models/quiz/questions_dto.dart';

abstract class CacheRemoteDataSource {
  Future<List<QuestionsDto>> getCacheQuestions();
}

class CacheDataSourceImpl implements CacheRemoteDataSource{
  @override
  Future<List<QuestionsDto>> getCacheQuestions() {
    // TODO: implement getCacheQuestions
    throw UnimplementedError();
  }
  
}