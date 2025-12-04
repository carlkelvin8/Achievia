import 'package:achievia/domain/entities/api/home/questions_entity.dart';
abstract class QuestionsRepository {
  Future<List<QuestionsEntity>> getAllQuestions(String token, String id);
}