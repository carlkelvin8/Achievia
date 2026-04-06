// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/const.dart';
import 'package:achievia/data/models/reviewer/module_dto.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

abstract class ModuleRepositoryDataSource {
  Future<PaginatedModulesDto> getModules(
    String token, {
    int page = 1,
    int limit = 20,
  });
}

@injectable
@lazySingleton
class ModuleRemoteDatasource implements ModuleRepositoryDataSource {
  final Dio dio;

  ModuleRemoteDatasource({
    required this.dio,
  });

  @override
  Future<PaginatedModulesDto> getModules(
    String token, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('[ModuleRemoteDatasource] GET /reviewer/modules?page=$page&limit=$limit');
      final response = await dio.get(
        '$BASE_URL/reviewer/modules',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final payload = response.data['data'] as Map<String, dynamic>;
        final data = payload['data'] as List;
        final hasPagination = payload['pagination'] is Map<String, dynamic>;
        final pagination = hasPagination
            ? payload['pagination'] as Map<String, dynamic>
            : <String, dynamic>{};

        final resolvedPage = (pagination['page'] as num?)?.toInt() ?? page;
        final resolvedLimit = (pagination['limit'] as num?)?.toInt() ?? limit;
        final resolvedTotal = (pagination['total'] as num?)?.toInt() ?? data.length;
        final resolvedHasMore = hasPagination
            ? (pagination['hasMore'] as bool? ?? data.length >= resolvedLimit)
            : false;

        print(
          '[ModuleRemoteDatasource] SUCCESS page=$resolvedPage '
          'limit=$resolvedLimit total=$resolvedTotal hasMore=$resolvedHasMore '
          'items=${data.length} hasPagination=$hasPagination',
        );

        return PaginatedModulesDto(
          items: data.map((module) => ModuleDto.fromJson(module)).toList(),
          page: resolvedPage,
          limit: resolvedLimit,
          total: resolvedTotal,
          hasMore: resolvedHasMore,
        );
      } else {
        print('[ModuleRemoteDatasource] FAILED status=${response.statusCode} page=$page');
        throw Exception('Failed to load modules: ${response.statusCode}');
      }
    } catch (e, st) {
      print('ModuleRemoteDatasource error: $e');
      print('Stack trace: $st');
      rethrow;
    }
  }
}

class PaginatedModulesDto {
  final List<ModuleDto> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  PaginatedModulesDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });
}
