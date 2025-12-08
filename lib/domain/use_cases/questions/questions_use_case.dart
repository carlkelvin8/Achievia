import 'package:achievia/data/repositoryImpl/questions/qot_repository_impl.dart';
import 'package:achievia/data/repositoryImpl/questions/questions_repository_impl.dart';
import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:injectable/injectable.dart';
@injectable
class QuestionsUseCase {
  final QuestionsRepositoryImpl impl;
  final QotRepositoryImpl impqot;
  QuestionsUseCase(this.impl, this.impqot);
  Future<List<QuestionsEntity>> getQuestions(String token,String id) async => await impl.getAllQuestions(token,  id);
  Future<QotyEntity> getQotQueston() async => await impqot.getQuestionOfTheDay();
}