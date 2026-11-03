import 'package:achievia/data/data_source/reviewer/question_bank_remote_datasource.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/repository/questions/study_deck_repository.dart';

class StudyDeckRepositoryImpl implements StudyDeckRepository {
  final QuestionBankRemoteDatasource dataSource;

  const StudyDeckRepositoryImpl(this.dataSource);

  @override
  Future<List<QuestionItemEntity>> getStudyQuestions(int quizId) =>
      dataSource.getStudyQuestions(quizId);
}
