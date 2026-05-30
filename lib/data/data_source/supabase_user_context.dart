import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseUserContext {
  const SupabaseUserContext();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<int> currentUserId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    final metadataId = _readId(user.userMetadata);
    if (metadataId != null) return metadataId;

    final nestedMetadata = user.userMetadata?['data'];
    final nestedId = _readId(nestedMetadata);
    if (nestedId != null) return nestedId;

    final email = user.email?.trim();
    if (email == null || email.isEmpty) {
      throw Exception('Authenticated user has no email');
    }

    final profile = await _supabase
        .from('profiles')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    final profileId = _readId(profile);
    if (profileId == null) {
      throw Exception('Authenticated user profile was not found');
    }

    return profileId;
  }

  int? _readId(dynamic source) {
    if (source is! Map) return null;

    final value = source['id'] ?? source['user_id'] ?? source['userId'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);

    return null;
  }
}
