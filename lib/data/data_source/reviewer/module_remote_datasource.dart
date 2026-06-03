// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:achievia/data/models/reviewer/module_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ModuleRepositoryDataSource {
  Future<PaginatedModulesDto> getModules({int page = 1, int limit = 20});
}

@injectable
@lazySingleton
class ModuleRemoteDatasource implements ModuleRepositoryDataSource {
  final SupabaseUserContext userContext;

  ModuleRemoteDatasource({this.userContext = const SupabaseUserContext()});

  SupabaseClient get _supabase => Supabase.instance.client;

  Map<String, dynamic> _normalizeModule(Map<String, dynamic> row) {
    return {
      ...row,
      'description': row['description'] ?? '',
      'userId': row['user_id'] ?? row['userId'] ?? 0,
      'createdAt': row['created_at'] ?? row['createdAt'] ?? '',
      'subjectId': row['subject_id'] ?? row['subjectId'] ?? 0,
    };
  }

  @override
  Future<PaginatedModulesDto> getModules({int page = 1, int limit = 20}) async {
    try {
      final userId = await userContext.currentUserId();
      final resolvedPage = page < 1 ? 1 : page;
      final resolvedLimit = limit < 1 ? 20 : (limit > 50 ? 50 : limit);
      final from = (resolvedPage - 1) * resolvedLimit;
      final to = from + resolvedLimit;

      final rows = await _supabase
          .from('modules')
          .select(
            'id, title, description, user_id, created_at, file, image, status, subject_id',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .range(from, to);

      final totalRows = await _supabase
          .from('modules')
          .select('id')
          .eq('user_id', userId);
      final hasMore = rows.length > resolvedLimit;
      final visibleRows = rows.take(resolvedLimit);

      return PaginatedModulesDto(
        items: visibleRows
            .map((module) => ModuleDto.fromJson(_normalizeModule(module)))
            .toList(),
        page: resolvedPage,
        limit: resolvedLimit,
        total: totalRows.length,
        hasMore: hasMore,
      );
    } catch (e, st) {
      debugPrint('ModuleRemoteDatasource error: $e');
      debugPrint('Stack trace: $st');
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
