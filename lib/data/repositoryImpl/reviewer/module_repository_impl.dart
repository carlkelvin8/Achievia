// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/network/conntectivity.dart';
import 'package:achievia/data/data_source/reviewer/module_remote_datasource.dart';
import 'package:achievia/domain/entities/api/reviewer/module_entity.dart';
import 'package:achievia/domain/repository/reviewer/module_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
@lazySingleton
class ModuleRepositoryImpl implements ModuleRepository {
  final ModuleRemoteDatasource remoteDatasource;
  final NetworkInfo network;

  ModuleRepositoryImpl({
    required this.remoteDatasource,
    required this.network,
  });

  @override
  Future<List<ModuleEntity>> getModules(String token) async {
    try {
      final connectivity = await network.isConnected;
      
      if (connectivity) {
        // Fetch from API and cache
        final remoteModules = await remoteDatasource.getModules(token);
        print('Repository - Remote modules received: $remoteModules');
        final mapped = remoteModules.map((dto) => dto.toEntity()).toList();
        print('Repository - Mapped to entities: $mapped');
        return mapped;
      } else {
        // Fetch from cache
        return [];
      }
    } catch (e, st) {
      print('ModuleRepositoryImpl error: $e');
      print('Stack trace: $st');
      rethrow;
    }
  }
}
