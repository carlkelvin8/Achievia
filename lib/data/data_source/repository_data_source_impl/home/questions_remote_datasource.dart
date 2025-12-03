import 'package:achievia/data/data_source/repository_data_source/home/question_repo_data_source.dart';
import 'package:achievia/data/models/quiz/questions_dto.dart';
import 'package:injectable/injectable.dart';

@singleton
class QuestionsRemoteDatasource implements QuestionRepoDataSource{
  @override
  Future<QuestionsDto> getAllQuestions(QuestionsDto dto) {
    // TODO: implement getAllQuestions
    throw UnimplementedError();
  }
  
}