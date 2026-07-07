import 'package:achievia/data/repositoryImpl/questions/qot_repository_impl.dart';
import 'package:achievia/data/repositoryImpl/questions/questions_repository_impl.dart';
import 'package:achievia/domain/entities/api/home/mockboard_paused_entity.dart';
import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/domain/entities/api/home/results_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:injectable/injectable.dart';

@injectable
class QuestionsUseCase {
  final QuestionsRepositoryImpl impl;
  final QotRepositoryImpl impqot;
  QuestionsUseCase(this.impl, this.impqot);

  Future<List<QuestionsEntity>> getQuestions() async =>
      await impl.getAllQuestions();

  Future<List<QuestionsEntity>> randomizeQuestions(int index) async =>
      await impl.generateQuestions(index);
  Future<QotyEntity> getQotQueston() async =>
      await impqot.getQuestionOfTheDay();
  Future<QotyEntityPost> answerQuestion(QotyEntityPost dto) async =>
      await impqot.answerQuestion(dto);
  Future<List<QuizItemEntity>> getGeneratedQuestions() async =>
      await impl.getRandomizedQuestions();
  Future<QuizScoreEntity?> getGWA(int noOfAttempt) async =>
      await impl.getQuizScores(noOfAttempt);
  Future<int> submitQuiz() async => await impl.submitQuiz();
  Future<MockboardPausedEntity> upsertContinueExam(MockboardPausedEntity entity) async => await impl.continueQuizRepository(entity);
  Future<MockboardPausedEntity> getContinueExam(MockboardPausedEntity entity) async => await impl.continuegetQuizRepository(entity);
}
