import 'package:supabase_flutter/supabase_flutter.dart';

abstract class DailyMotivationDataSource {
  Future<List<Map<String, dynamic>>> fetchActive();
  Future<List<Map<String, dynamic>>> fetchAll();
  Future<void> insert(String message, {required int displayOrder});
  Future<void> updateMessage(String id, String message);
  Future<void> setActive(String id, bool active);
  Future<void> delete(String id);
  Future<bool> isAdmin();
}

/// Access control is enforced by RLS on `daily_motivations`; checks in the app
/// only decide what to show.
class DailyMotivationRemoteDatasource implements DailyMotivationDataSource {
  static const _columns = 'id, message, is_active, display_order, created_at';

  SupabaseClient get _supabase => Supabase.instance.client;

  List<Map<String, dynamic>> _rows(Object? response) => (response as List)
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList();

  @override
  Future<List<Map<String, dynamic>>> fetchActive() async => _rows(
    await _supabase
        .from('daily_motivations')
        .select(_columns)
        .eq('is_active', true)
        .order('display_order')
        .order('created_at')
        .order('id'),
  );

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async => _rows(
    await _supabase
        .from('daily_motivations')
        .select(_columns)
        .order('display_order')
        .order('created_at')
        .order('id'),
  );

  @override
  Future<void> insert(String message, {required int displayOrder}) async {
    await _supabase.from('daily_motivations').insert({
      'message': message,
      'display_order': displayOrder,
      'created_by': _supabase.auth.currentUser?.id,
    });
  }

  @override
  Future<void> updateMessage(String id, String message) async {
    await _supabase
        .from('daily_motivations')
        .update({'message': message})
        .eq('id', id);
  }

  @override
  Future<void> setActive(String id, bool active) async {
    await _supabase
        .from('daily_motivations')
        .update({'is_active': active})
        .eq('id', id);
  }

  @override
  Future<void> delete(String id) async {
    await _supabase.from('daily_motivations').delete().eq('id', id);
  }

  @override
  Future<bool> isAdmin() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    final row = await _supabase
        .from('profiles')
        .select('role, status')
        .eq('id', userId)
        .maybeSingle();
    return row != null && row['role'] == 'ADMIN' && row['status'] == 'active';
  }
}
