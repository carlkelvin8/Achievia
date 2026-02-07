// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/data/models/quiz/qotd_dto_post.dart';
import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:injectable/injectable.dart';

import 'package:achievia/core/network/conntectivity.dart';
import 'package:achievia/data/data_source/home/questions_remote_datasource.dart';
import 'package:achievia/domain/repository/questions/qotd_repository.dart';

@lazySingleton
@injectable
class QotRepositoryImpl implements QotdRepository {
  final QuestionsRemoteDatasource remoteDatasource;
  final NetworkInfo network; 
  QotRepositoryImpl({
    required this.remoteDatasource,
    required this.network,
  });
  @override
  Future<QotyEntity> getQuestionOfTheDay() async {
    final connectivity = await network.isConnected;
    try {
      if (connectivity) {
        final remoteQuestion = await remoteDatasource.getQotd();
        final entity = remoteQuestion.toEntity();
        return entity;
      }
      return QotyEntity(quizId: 0, id: 0, questionText: '', choices: []);
    } catch (e) {
      print('repo: $e');
      rethrow;
    }
  }

  @override
  Future<QotyEntityPost> answerQuestion(QotyEntityPost entity) async {
    final connectivity = await network.isConnected;
    try {
      if (connectivity) {
        final dto = QotdDtoPost.fromEntity(entity);
        final remoteAnswer = await remoteDatasource.answerQuestion(dto, '');
        print(remoteAnswer.chosen_answer);
        return remoteAnswer.toEntity();
      }
      return QotyEntityPost(chosen_ans: '', quiz_id: 0, student_id: 0);
    } catch (e) {
      print('repos: $e');
      return QotyEntityPost(chosen_ans: '', quiz_id: 0, student_id: 0);
    }
  }
}
