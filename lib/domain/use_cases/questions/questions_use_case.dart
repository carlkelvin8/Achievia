import 'package:achievia/data/repositoryImpl/questions/qot_repository_impl.dart';
import 'package:achievia/data/repositoryImpl/questions/questions_repository_impl.dart';
import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/domain/entities/api/home/results_entity.dart';
import 'package:injectable/injectable.dart';
@injectable
class QuestionsUseCase {
  final QuestionsRepositoryImpl impl;
  final QotRepositoryImpl impqot;
  QuestionsUseCase(this.impl, this.impqot);
  Future<List<QuestionsEntity>> getQuestions(String token,String id) async => await impl.getAllQuestions(token,  id);
  Future<List<QuestionsEntity>> randomizeQuestions(int index) async => await impl.generateQuestions(index);
  Future<QotyEntity> getQotQueston() async => await impqot.getQuestionOfTheDay();
  Future<QotyEntityPost> answerQuestion(QotyEntityPost dto) async => await impqot.answerQuestion(dto);
  Future<List<QotyEntity>> getGeneratedQuestions() async => await impl.getRandomizedQuestions();
  Future<QuizScoreEntity?> getGWA(int noOfAttempt) async => await impl.getQuizScores(noOfAttempt);
  Future<int> submitQuiz() async => await impl.submitQuiz();
}