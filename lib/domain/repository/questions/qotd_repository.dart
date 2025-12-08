import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:achievia/domain/entities/widgets/qotd_entity.dart';

abstract class QotdRepository {
  Future<QotyEntity> getQuestionOfTheDay();
}