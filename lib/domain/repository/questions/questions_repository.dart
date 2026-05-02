import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/domain/entities/api/home/results_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
abstract class QuestionsRepository {
  Future<List<QuestionsEntity>> getAllQuestions(String token, String od);
  Future<List<QuestionsEntity>> generateQuestions(int index);
  Future<List<QuizItemEntity>> getRandomizedQuestions();
  Future<QuizScoreEntity?> getQuizScores(int noOfAttempt);
  Future<int> submitQuiz();
}