import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:achievia/domain/entities/api/profile/profile_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProfileDataSource {
  Future<ProfileEntity> getProfile();
}

@injectable
@lazySingleton
class ProfileRemoteDatasource implements ProfileDataSource {
  final SupabaseUserContext userContext;

  ProfileRemoteDatasource({this.userContext = const SupabaseUserContext()});

  SupabaseClient get _supabase => Supabase.instance.client;

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  Future<ProfileEntity> getProfile() async {
    try {
      final userId = await userContext.currentUserId();
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return ProfileEntity(
        id: _parseInt(data['id']),
        firstName: data['first_name'] as String?,
        middleName: data['middle_name'] as String?,
        lastName: data['last_name'] as String?,
        bio: data['bio'] as String?,
        email: data['email'] as String?,
        age: _parseInt(data['age']),
        trial: data['trial']?.toString(),
        username: data['username'] as String?,
        role: data['role'] as String?,
        university: data['university'] as String?,
        purpose: data['purpose'] as String?,
        dateOfExamination: _parseDate(data['date_of_examination']),
        createdAt: _parseDate(data['created_at']),
        updatedAt: _parseDate(data['updated_at']),
        status: data['status'] as String?,
        profileImage: data['profile_image'] as String?,
        courseId: _parseInt(data['course_id']),
      );
    } catch (e, st) {
      debugPrint('Error fetching profile: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }
}
