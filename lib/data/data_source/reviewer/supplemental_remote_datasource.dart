import 'package:achievia/data/models/reviewer/supplemental_item_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SupplementalDataSource {
  Future<List<SupplementalItemDto>> getItems({int? courseId});
}

@lazySingleton
@injectable
class SupplementalRemoteDatasource implements SupplementalDataSource {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<List<SupplementalItemDto>> getItems({int? courseId}) async {
    var query = _supabase
        .from('supplemental_items')
        .select('id, course_id, kind, title, content, image_url, file_url')
        .eq('is_active', true);
    if (courseId != null) query = query.eq('course_id', courseId);
    final rows = await query.order('sort_order').order('id');
    return rows
        .map(
          (row) => SupplementalItemDto.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }
}
