import 'package:achievia/data/models/quiz/questions_dto.dart';

abstract class QuestionRepoDataSource  {
  Future<QuestionsDto> getAllQuestions(QuestionsDto dto);
}