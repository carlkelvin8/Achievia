// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/data/models/quiz/qotd_dto_post.dart';
import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:injectable/injectable.dart';

import 'package:achievia/data/data_source/home/questions_remote_datasource.dart';
import 'package:achievia/domain/repository/questions/qotd_repository.dart';

@lazySingleton
@injectable
class QotRepositoryImpl implements QotdRepository {
  final QuestionsRemoteDatasource remoteDatasource;
  QotRepositoryImpl({required this.remoteDatasource});
  @override
  Future<QotyEntity> getQuestionOfTheDay() async {
    try {
      final remoteQuestion = await remoteDatasource.getQotd();
      return remoteQuestion.toEntity();
    } catch (e) {
      print('repo: $e');
      rethrow;
    }
  }

  @override
  Future<QotyEntityPost> answerQuestion(QotyEntityPost entity) async {
    try {
      final dto = QotdDtoPost.fromEntity(entity);
      final remoteAnswer = await remoteDatasource.answerQuestion(dto);
      return remoteAnswer.toEntity();
    } catch (e) {
      print('repos: $e');
      return QotyEntityPost(chosen_ans: '', quiz_id: 0, student_id: '');
    }
  }
}
