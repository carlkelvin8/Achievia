import 'package:achievia/core/network/dio_client.dart';
import 'package:achievia/data/models/quiz/questions_dto.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

abstract class QuestionRepoDataSource  {
  Future<List<QuestionsDto>> getAllQuestions(QuestionsDto dto, String token);
}
@LazySingleton(as: QuestionRepoDataSource)
class QuestionsRemoteDatasource implements QuestionRepoDataSource{
  final DioClient dio;
  QuestionsRemoteDatasource(this.dio);
  @override
  Future<List<QuestionsDto>> getAllQuestions(QuestionsDto dto, String token) async{
    try {
      final response = await dio.dio.get('tasks/getQuiz?id=${dto.id}', options: Options(
        headers: {
          'Content-Type':'application/json',
          'Authorization': 'Bearer $token'
        }
      ));
      final list = (response.data as List)
      .map((e)=>QuestionsDto.fromJson(e as Map<String, dynamic>)).toList();
      return list;
    } catch (e) {
      rethrow;
    }
  }
  
}