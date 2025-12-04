import 'package:achievia/data/models/quiz/questions_dto.dart';
import 'package:injectable/injectable.dart';

abstract class QuestionRepoDataSource  {
  Future<QuestionsDto> getAllQuestions(QuestionsDto dto);
}
@LazySingleton(as: QuestionRepoDataSource)
class QuestionsRemoteDatasource implements QuestionRepoDataSource{
  @override
  Future<QuestionsDto> getAllQuestions(QuestionsDto dto) {
    // TODO: implement getAllQuestions
    throw UnimplementedError();
  }
  
}