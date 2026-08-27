import 'package:achievia/domain/entities/api/home/mockboard_paused_entity.dart';
import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/domain/entities/api/home/results_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/entities/widgets/examination_results_entity.dart';

abstract class QuestionsRepository {
  Future<List<QuestionsEntity>> getAllQuestions();
  Future<List<QuestionsEntity>> generateQuestions(int index);
  Future<List<QuizItemEntity>> getRandomizedQuestions();
  Future<QuizScoreEntity?> getQuizScores(int noOfAttempt);
  Future<int> submitQuiz();
  Future<MockboardPausedEntity> continueQuizRepository(
    MockboardPausedEntity entity,
  );
  Future<MockboardPausedEntity> continuegetQuizRepository(
    MockboardPausedEntity entity,
  );
  Future<List<ExaminationResult>> getRecentAttemptResults();
}
