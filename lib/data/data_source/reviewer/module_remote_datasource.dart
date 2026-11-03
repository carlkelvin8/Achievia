// ignore_for_file: public_member_api_docs, sort_constructors_first
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
  ModuleRemoteDatasource();

  SupabaseClient get _supabase => Supabase.instance.client;

  Map<String, dynamic> _normalizeModule(Map<String, dynamic> row) {
    return {
      ...row,
      'description': row['description'] ?? '',
      'userId': (row['user_id'] ?? row['userId'] ?? '').toString(),
      'createdAt': (row['created_at'] ?? row['createdAt'] ?? '').toString(),
      'subjectId': (row['subject_id'] ?? row['subjectId'] ?? 0) is int
          ? (row['subject_id'] ?? row['subjectId'] ?? 0)
          : int.tryParse(
                  (row['subject_id'] ?? row['subjectId'] ?? 0).toString(),
                ) ??
                0,
    };
  }

  /// True when the error says the relation itself does not exist (view not
  /// deployed). Permission, network and other errors stay real failures.
  static bool _isViewMissing(PostgrestException error) =>
      error.code == 'PGRST205' || error.code == '42P01';

  Future<List<Map<String, dynamic>>> _queryPublished(
    String relation,
    int from,
    int to, {
    bool onTable = false,
  }) async {
    var query = _supabase
        .from(relation)
        .select(
          'id, title, description, user_id, created_at, file, image, status, subject_id',
        );
    if (onTable) {
      query = query.eq('status', 'published').isFilter('deleted_at', null);
    }
    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(from, to);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<PaginatedModulesDto> getModules({int page = 1, int limit = 20}) async {
    try {
      final resolvedPage = page < 1 ? 1 : page;
      final resolvedLimit = limit < 1 ? 20 : (limit > 50 ? 50 : limit);
      final from = (resolvedPage - 1) * resolvedLimit;
      // Fetch one extra row to determine hasMore without a separate count query
      final to = from + resolvedLimit;

      // The invoker-security view filters published rows before pagination.
      // Projects where the view is not deployed yet fall back to the same
      // filter applied directly on the table, so the list never breaks.
      List<Map<String, dynamic>> rows;
      try {
        rows = await _queryPublished('published_modules', from, to);
      } on PostgrestException catch (error) {
        if (!_isViewMissing(error)) rethrow;
        debugPrint(
          'published_modules unavailable (${error.code}); table query',
        );
        rows = await _queryPublished('modules', from, to, onTable: true);
      }

      final hasMore = rows.length > resolvedLimit;
      final visibleRows = rows.take(resolvedLimit).toList();

      final estimatedTotal = hasMore
          ? (resolvedPage * resolvedLimit) + 1
          : (resolvedPage - 1) * resolvedLimit + visibleRows.length;

      return PaginatedModulesDto(
        items: visibleRows
            .map((module) => ModuleDto.fromJson(_normalizeModule(module)))
            .toList(),
        page: resolvedPage,
        limit: resolvedLimit,
        total: estimatedTotal,
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
