import 'package:achievia/data/repositoryImpl/questions/questions_repository_impl.dart';
import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:injectable/injectable.dart';
@injectable
class QuestionsUseCase {
  final QuestionsRepositoryImpl impl;
  QuestionsUseCase(this.impl);
  Future<List<QuestionsEntity>> getQuestions(String token) async => await impl.getAllQuestions(token);
}