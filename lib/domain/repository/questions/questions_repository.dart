import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/domain/entities/api/home/results_entity.dart';
abstract class QuestionsRepository {
  Future<List<QuestionsEntity>> getAllQuestions(String token, String od);
  Future<List<QuestionsEntity>> generateQuestions();
  Future<List<QotyEntity>> getRandomizedQuestions();
  Future<QuizScoreEntity?> getQuizScores();
  Future<String> submitQuiz();
}