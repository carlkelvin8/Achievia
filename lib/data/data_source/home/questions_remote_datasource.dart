import 'package:achievia/const.dart';
import 'package:achievia/data/models/quiz/qotd_dto.dart';
import 'package:achievia/data/models/quiz/qotd_dto_post.dart';
import 'package:achievia/data/models/quiz/questions_dto.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

abstract class QuestionRepoDataSource  {
  Future<List<QuestionsDto>> getAllQuestions(String token, String id);
  Future<QotdDto> getQotd();
  Future<QotdDtoPost> answerQuestion(QotdDtoPost dto, String token);
  Future<List<QuestionsDto>> randomizeQuestion();
  
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
    final questionData = response.data['data']['response'] as List<dynamic>;

    final questionsList = questionData.map((e)=>QuestionsDto.fromJson(e)).toList();

    return questionsList;
  } catch (e) {
    rethrow;
  }
}

  @override
  Future<QotdDto> getQotd() async{
    try {
      final response = await dio.get('$BASE_URL/tasks/get1Question', 
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        }
      )
      );
      final questionMap = Map<String, dynamic>.from(response.data['data']['response']['question']);
      final choicesList = List<Map<String, dynamic>>.from(response.data['data']['response']['choices'] ?? []);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final flattened = {
          ...questionMap,
          'choices': choicesList,
        };
        return QotdDto.fromJson(flattened);
      }else{
        return QotdDto.fromJson(await response.data);
      }
    } catch (e) {
      print(e);
      return QotdDto.fromJson({});
    }
  }
  
  @override
  Future<QotdDtoPost> answerQuestion(QotdDtoPost dto, String token) async{
    try {
      final response  =  await dio.post('$BASE_URL/tasks/ansQuestion', 
      options: Options(
        headers: {
          'Content-Type':'application/json',
          'Authorization': 'Bearer $token'
        }
      ),
      data: dto.toJson()
      );
      print('datasource: ${response.data}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return dto;
      }
      return dto;
    } catch (e) {
      print(e);
      return QotdDtoPost.fromJson({});
    }
  }
  
  @override
  Future<List<QuestionsDto>> randomizeQuestion() async{
    try {
      final response = await dio.post('$BASE_URL/tasks/randomizeQuestions', 
      options: Options(
        headers: {
          'Content-Type':'application/json'
        }
      )
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = await response.data['data']['response'] as List<dynamic>;
        final list =  data.map((e)=> QuestionsDto.fromJson(e)).toList();
        print(list);
        return list;
      }
      return [];
    } catch (e) {
      print(e);
      return [];
    }
  }
}