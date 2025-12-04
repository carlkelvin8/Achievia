import 'package:achievia/core/network/conntectivity.dart';
import 'package:achievia/data/data_source/repository_data_source_impl/cache/cache_data_source_impl.dart';
import 'package:achievia/data/data_source/repository_data_source_impl/home/questions_remote_datasource.dart';
import 'package:achievia/data/models/quiz/questions_dto.dart';
import 'package:achievia/domain/entities/api/home/questions_entity.dart';
import 'package:achievia/domain/repository/questions/questions_repository.dart';
import 'package:injectable/injectable.dart';
@lazySingleton
@injectable
class QuestionsRepositoryImpl implements QuestionsRepository{
  final QuestionsRemoteDatasource remoteDatasource;
  final CacheDataSourceImpl local;
  final NetworkInfo network;

  QuestionsRepositoryImpl(this.local, this.remoteDatasource, this.network);
  @override
  Future<List<QuestionsEntity>> getAllQuestions(String token, String id) async{
    try {
      final connectivity = await network.isConnected;
      if (connectivity) {
        final remoteQuestions = await remoteDatasource.getAllQuestions(token, id);
        print('Repository - Remote questions received: $remoteQuestions');
        //await local.cachePost(remoteQuestions);
        final mapped = remoteQuestions.map((e)=>e.toEntity()).toList();
        print('Repository - Mapped to entities: $mapped');
        return mapped;

      }else{
        final cached = await local.getCacheQuestions();
        return cached.map((e)=>e.toEntity()).toList();
      }
    } catch (e, st) {
      print('Repository error: $e');
      print('Repository stacktrace: $st');
      rethrow;
    }
  }
  
}