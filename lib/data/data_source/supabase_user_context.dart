import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@injectable
@lazySingleton
class SupabaseUserContext {
  const SupabaseUserContext();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<String> currentUserId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    final userId = user.id;

    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (profile == null) {
      throw Exception('Authenticated user profile was not found');
    }

    return userId;
  }
}
