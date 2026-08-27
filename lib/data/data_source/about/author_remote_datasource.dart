import 'package:achievia/data/models/about/author_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthorDataSource {
  Future<List<AuthorDto>> getAuthors();
}

@lazySingleton
@injectable
class AuthorRemoteDatasource implements AuthorDataSource {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<List<AuthorDto>> getAuthors() async {
    final rows = await _supabase
        .from('authors')
        .select(
          'id, name, university, achievement, greeting, message, image_url',
        )
        .eq('is_active', true)
        .order('sort_order')
        .order('id');
    return rows
        .map((row) => AuthorDto.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }
}
