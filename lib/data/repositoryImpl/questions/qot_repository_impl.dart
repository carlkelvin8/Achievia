// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/data/models/quiz/qotd_dto.dart';
import 'package:achievia/domain/entities/api/home/qoty_entity.dart';
import 'package:injectable/injectable.dart';

import 'package:achievia/core/network/conntectivity.dart';
import 'package:achievia/data/data_source/repository_data_source_impl/cache/cache_data_source_impl.dart' show CacheDataSourceImpl;
import 'package:achievia/data/data_source/repository_data_source_impl/home/questions_remote_datasource.dart';
import 'package:achievia/domain/repository/questions/qotd_repository.dart';
@lazySingleton
@injectable
class QotRepositoryImpl implements QotdRepository {
  final QuestionsRemoteDatasource remoteDatasource;
  final CacheDataSourceImpl local;
  final NetworkInfo network; 
  QotRepositoryImpl({
    required this.remoteDatasource,
    required this.local,
    required this.network,
  });
  @override
  Future<QotyEntity> getQuestionOfTheDay() async{
    final connectivity = await network.isConnected;
    try {
      if (connectivity) {
        final remoteQuestion = await remoteDatasource.getQotd();
        final entity =  remoteQuestion.toEntity();
        return entity;
      }
      return QotyEntity(quizId: 0, id: 0, questionText: '', choices: []);
    } catch (e) {
      print('repo: $e');
      rethrow;
    }
  }
  
}
