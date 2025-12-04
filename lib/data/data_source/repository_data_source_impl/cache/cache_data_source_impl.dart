import 'package:achievia/data/models/quiz/questions_dto.dart';
import 'package:hive/hive.dart';
import "package:injectable/injectable.dart";
abstract class CacheRemoteDataSource {
  Future<List<QuestionsDto>> getCacheQuestions();
  Future<void> cachePost(List<QuestionsDto> cache);
}

@injectable
class CacheDataSourceImpl implements CacheRemoteDataSource{
  final Box<QuestionsDto> box;
  CacheDataSourceImpl(@Named('question_box') this.box);

  @override
  Future<List<QuestionsDto>> getCacheQuestions() async{
      return box.values.toList();
  }
  
  @override
  Future<void> cachePost(List<QuestionsDto> cache) async{
    await box.clear();
    for (var c in cache) {
      await box.put(c.id, c);
    }
  }
  
}