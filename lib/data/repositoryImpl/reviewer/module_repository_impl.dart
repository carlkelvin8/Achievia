// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/network/conntectivity.dart';
import 'package:achievia/data/data_source/reviewer/module_remote_datasource.dart';
import 'package:achievia/domain/entities/api/reviewer/paginated_modules_entity.dart';
import 'package:achievia/domain/repository/reviewer/module_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
@lazySingleton
class ModuleRepositoryImpl implements ModuleRepository {
  final ModuleRemoteDatasource remoteDatasource;
  final NetworkInfo network;

  ModuleRepositoryImpl({required this.remoteDatasource, required this.network});

  @override
  Future<PaginatedModulesEntity> getModules({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final connectivity = await network.isConnected;

      if (connectivity) {
        final remoteModules = await remoteDatasource.getModules(
          page: page,
          limit: limit,
        );
        print('Repository - Remote modules received: $remoteModules');
        final mapped = remoteModules.items
            .map((dto) => dto.toEntity())
            .toList();
        print('Repository - Mapped to entities: $mapped');
        return PaginatedModulesEntity(
          items: mapped,
          page: remoteModules.page,
          limit: remoteModules.limit,
          total: remoteModules.total,
          hasMore: remoteModules.hasMore,
        );
      } else {
        // Fetch from cache
        return PaginatedModulesEntity(
          items: const [],
          page: page,
          limit: limit,
          total: 0,
          hasMore: false,
        );
      }
    } catch (e, st) {
      print('ModuleRepositoryImpl error: $e');
      print('Stack trace: $st');
      rethrow;
    }
  }
}
