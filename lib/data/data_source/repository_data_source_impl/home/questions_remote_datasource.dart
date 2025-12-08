import 'package:achievia/const.dart';
import 'package:achievia/data/models/quiz/questions_dto.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

abstract class QuestionRepoDataSource  {
  Future<List<QuestionsDto>> getAllQuestions(String token);
}
@lazySingleton
@injectable
class QuestionsRemoteDatasource implements QuestionRepoDataSource{
  final Dio dio;
  QuestionsRemoteDatasource(this.dio);
 @override
Future<List<QuestionsDto>> getAllQuestions(String token) async {
  try {
    final response = await dio.get(
      '$BASE_URL/tasks/getQuiz',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ),
    );
    final questionData = response.data['data']['response'] as Map<String, dynamic>;

    final questionsList = [QuestionsDto.fromJson(questionData)];

    return questionsList;
  } catch (e) {
    rethrow;
  }
}

  
}