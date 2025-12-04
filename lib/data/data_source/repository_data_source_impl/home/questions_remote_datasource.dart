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
  print('API call started...');
  try {
    final response = await dio.get(
      'http://10.0.2.2:5000/tasks/getQuiz?id=$id',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-user-id':id
        },
      ),
    );
    print('Response received: ${response.data}');

    // Extract the single question from the response
    final questionData = response.data['data']['response'] as Map<String, dynamic>;
    print('Question data extracted: $questionData');

    // Wrap it in a list for repository compatibility
    final questionsList = [QuestionsDto.fromJson(questionData)];
    print('DTO created successfully: $questionsList');

    return questionsList;
  } catch (e, st) {
    print('API error: $e');
    print('StackTrace: $st');
    rethrow;
  }
}

  
}