import 'package:achievia/const.dart';
import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:achievia/data/models/profile/profile_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProfileDataSource {
  Future<ProfileDto> getProfile();
  Future<String> updateMantra(String mantra);
}

@injectable
@lazySingleton
class ProfileRemoteDatasource implements ProfileDataSource {
  final SupabaseUserContext userContext;

  ProfileRemoteDatasource({this.userContext = const SupabaseUserContext()});

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<ProfileDto> getProfile() async {
    try {
      final userId = await supabaseAuth.getUser();
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId.user?.id ?? "")
          .single();

      return ProfileDto.fromJson(data);
    } catch (e, st) {
      debugPrint('Error fetching profile: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  @override
  Future<String> updateMantra(String mantra) async {
    try {
      final userId = await supabaseAuth.getUser();
      final profileId = userId.user?.id;
      if (profileId == null || profileId.isEmpty) {
        throw Exception('Authenticated user profile was not found');
      }

      await _supabase
          .from('profiles')
          .update({'mantra': mantra.trim()})
          .eq('id', profileId);

      return 'Mantra has been updated successfully';
    } catch (e, st) {
      debugPrint('Error updating mantra: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }
}
