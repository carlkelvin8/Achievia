import 'package:achievia/domain/entities/api/home/qoty_entity.dart';

abstract class QotdRepository {
  Future<QotyEntity> getQuestionOfTheDay();
  Future<QotyEntityPost> answerQuestion(QotyEntityPost entity);
}