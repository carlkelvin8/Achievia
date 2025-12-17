import 'package:achievia/data/models/quiz/qotd_dto.dart';
import 'package:hive/hive.dart';
import "package:injectable/injectable.dart";
abstract class MockBoardsQuestionsDataSource {
  Future<List<QotdDto>> getCacheQuestions();
  Future<void> cachePost(List<QotdDto> cache);
}

@injectable
class MockBoardsQuestionsDataSourceImpl implements MockBoardsQuestionsDataSource{
  final Box<QotdDto> box;
  MockBoardsQuestionsDataSourceImpl(@Named('exam_box') this.box);
  
  @override
  Future<List<QotdDto>> getCacheQuestions() async{
      return box.values.toList();
  }
  
  
  @override
  Future<void> cachePost(List<QotdDto> cache) async{
    await box.clear();
    for (var c in cache) {
      await box.put(c.id, c);
    }
  }
}