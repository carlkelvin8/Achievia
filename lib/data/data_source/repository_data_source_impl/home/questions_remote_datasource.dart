import 'package:achievia/const.dart';
import 'package:achievia/data/models/quiz/questions_dto.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

abstract class QuestionRepoDataSource  {
  Future<List<QuestionsDto>> getAllQuestions(String token, String id);
}
@lazySingleton
@injectable
class QuestionsRemoteDatasource implements QuestionRepoDataSource{
  final Dio dio;
  QuestionsRemoteDatasource(this.dio);
 @override
Future<List<QuestionsDto>> getAllQuestions(String token, String id) async {
  try {
    final response = await dio.get(
      '$BASE_URL/tasks/getQuiz?id=$id',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-user-id':id
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