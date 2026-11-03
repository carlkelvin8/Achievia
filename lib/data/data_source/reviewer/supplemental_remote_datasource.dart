import 'package:achievia/const.dart';
import 'package:achievia/data/models/reviewer/supplemental_item_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SupplementalDataSource {
  Future<List<SupplementalItemDto>> getItems({int? courseId});
  Future<Map<int, String>> getSubjectTitles(Iterable<int> subjectIds);
}

@lazySingleton
@injectable
class SupplementalRemoteDatasource implements SupplementalDataSource {
  final SupabaseClient? _client;

  SupplementalRemoteDatasource({@ignoreParam SupabaseClient? client})
    : _client = client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  // Public URL builder for the admin storage bucket
  String _storageUrl(String path) =>
      '$supabaseUrl/storage/v1/object/public/admin/$path';

  @override
  Future<List<SupplementalItemDto>> getItems({int? courseId}) async {
    // The profile stores a course id, but these tables reference subjects.
    final subjectIds = courseId == null
        ? null
        : await _subjectIdsForCourse(courseId);

    // Fetch from the real tables in parallel
    final results = await Future.wait([
      _fetchMnemonics(subjectIds: subjectIds),
      _fetchAbbreviations(subjectIds: subjectIds),
      _fetchProcedures(subjectIds: subjectIds),
    ]);

    return [...results[0], ...results[1], ...results[2]];
  }

  /// Names of the given subjects, from the same `subjects` table the rest of
  /// the app reads. Unknown ids are simply absent from the result.
  @override
  Future<Map<int, String>> getSubjectTitles(Iterable<int> subjectIds) async {
    final ids = subjectIds.toSet().toList();
    if (ids.isEmpty) return const {};
    final rows = await _supabase
        .from('subjects')
        .select('id, title')
        .inFilter('id', ids);
    return {
      for (final row in rows)
        if (row['id'] is num && row['title'] != null)
          (row['id'] as num).toInt(): row['title'].toString(),
    };
  }

  Future<List<int>> _subjectIdsForCourse(int courseId) async {
    final rows = await _supabase
        .from('subjects')
        .select('id')
        .eq('course_id', courseId);
    return [
      for (final row in rows)
        if (row['id'] is num) (row['id'] as num).toInt(),
    ];
  }

  /// Items of the course's subjects plus global items (no subject).
  String _subjectFilter(List<int> subjectIds) => subjectIds.isEmpty
      ? 'subject_id.is.null'
      : 'subject_id.in.(${subjectIds.join(',')}),subject_id.is.null';

  /// Reads every row of a query. A single response is capped by the API, so
  /// the list is fetched page by page instead of being silently truncated.
  Future<List<Map<String, dynamic>>> _allRows(
    PostgrestTransformBuilder<PostgrestList> Function() build,
  ) async {
    const pageSize = 1000;
    final rows = <Map<String, dynamic>>[];
    for (var from = 0; ; from += pageSize) {
      final page = await build().range(from, from + pageSize - 1);
      rows.addAll(page);
      if (page.length < pageSize) break;
    }
    return rows;
  }

  Future<List<SupplementalItemDto>> _fetchMnemonics({
    List<int>? subjectIds,
  }) async {
    final rows = await _allRows(() {
      var query = _supabase
          .from('mnemonics')
          .select('id, subject_id, title, file_path, description')
          .filter('deleted_at', 'is', null);
      if (subjectIds != null) {
        query = query.or(_subjectFilter(subjectIds));
      }
      return query.order('id');
    });
    return rows.map((row) {
      final path = (row['file_path'] as String?)?.trim() ?? '';
      return SupplementalItemDto(
        id: (row['id'] as num).toInt(),
        courseId: row['subject_id'] as int?,
        kind: 'mnemonic',
        title: (row['title'] as String?) ?? '',
        content: (row['description'] as String?) ?? '',
        imageUrl: path.isNotEmpty ? _storageUrl(path) : null,
        fileUrl: null,
        subjectId: row['subject_id'] as int?,
      );
    }).toList();
  }

  Future<List<SupplementalItemDto>> _fetchAbbreviations({
    List<int>? subjectIds,
  }) async {
    final rows = await _allRows(() {
      var query = _supabase
          .from('abbreviations')
          .select('id, subject_id, short_form, full_form, description')
          .filter('deleted_at', 'is', null);
      if (subjectIds != null) {
        query = query.or(_subjectFilter(subjectIds));
      }
      return query.order('id');
    });
    return rows.map((row) {
      return SupplementalItemDto(
        id: (row['id'] as num).toInt(),
        courseId: row['subject_id'] as int?,
        kind: 'abbreviation',
        title: (row['short_form'] as String?) ?? '',
        content: (row['full_form'] as String?) ?? '',
        description: (row['description'] as String?) ?? '',
        imageUrl: null,
        fileUrl: null,
        subjectId: row['subject_id'] as int?,
      );
    }).toList();
  }

  Future<List<SupplementalItemDto>> _fetchProcedures({
    List<int>? subjectIds,
  }) async {
    final rows = await _allRows(() {
      var query = _supabase
          .from('procedures')
          .select('id, subject_id, title, file_path')
          .filter('deleted_at', 'is', null);
      if (subjectIds != null) {
        query = query.or(_subjectFilter(subjectIds));
      }
      return query.order('id');
    });
    return rows.map((row) {
      final path = (row['file_path'] as String?)?.trim() ?? '';
      return SupplementalItemDto(
        id: (row['id'] as num).toInt(),
        courseId: row['subject_id'] as int?,
        kind: 'procedure',
        title: (row['title'] as String?) ?? '',
        content: '',
        imageUrl: null,
        fileUrl: path.isNotEmpty ? _storageUrl(path) : null,
      );
    }).toList();
  }
}
