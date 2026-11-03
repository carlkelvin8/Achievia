// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/network/conntectivity.dart';
import 'package:achievia/data/data_source/reviewer/module_remote_datasource.dart';
import 'package:achievia/domain/entities/api/reviewer/paginated_modules_entity.dart';
import 'package:achievia/domain/repository/reviewer/module_repository.dart';
import 'package:flutter/foundation.dart';
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
      final isConnected = await network.isConnected;

      if (!isConnected) {
        // No local cache — propagate as an error so the UI shows the retry
        // button instead of silently claiming there are no modules.
        throw Exception(
          'No internet connection. Please check your network and try again.',
        );
      }

      final remoteModules = await remoteDatasource.getModules(
        page: page,
        limit: limit,
      );

      final mapped = remoteModules.items.map((dto) => dto.toEntity()).toList();

      return PaginatedModulesEntity(
        items: mapped,
        page: remoteModules.page,
        limit: remoteModules.limit,
        total: remoteModules.total,
        hasMore: remoteModules.hasMore,
      );
    } catch (e, st) {
      debugPrint('ModuleRepositoryImpl error: $e');
      debugPrint('$st');
      rethrow;
    }
  }
}
