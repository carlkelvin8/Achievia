import 'package:achievia/const.dart';
import 'package:achievia/core/utils/auth_error_utils.dart';
import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:achievia/data/models/profile/profile_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProfileDataSource {
  Future<ProfileDto> getProfile();
  Future<String> updateMantra(String mantra);
  Future<void> updatePurpose(String purpose);
  Future<void> updateExamDate(DateTime date);
  Future<void> updateDetails(Map<String, Object?> fields);

  /// Uploads [jpegBytes] as the student's profile picture and returns its
  /// public URL after saving it on the profile.
  Future<String> uploadProfileImage(Uint8List jpegBytes);

  /// Clears the profile picture and deletes the uploaded file.
  Future<void> removeProfileImage();
}

/// A safe, specific message for a failed profile picture upload or removal.
String profileImageErrorMessage(Object error) {
  if (error is StorageException) {
    final status = error.statusCode;
    final text = error.message.toLowerCase();
    if (text.contains('bucket not found') || status == '404') {
      return 'Profile pictures are not set up yet. Please try again later.';
    }
    if (status == '413' || text.contains('too large')) {
      return 'That picture is too large (max 2 MB).';
    }
    if (status == '401' || status == '403' || text.contains('policy')) {
      return 'You are not allowed to change this picture. Please sign in '
          'again.';
    }
    if (text.contains('mime') || status == '415') {
      return 'Use a JPG, PNG or WebP picture.';
    }
  }
  return 'Unable to update your picture. ${userFacingError(error)}';
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

  @override
  Future<void> updatePurpose(String purpose) async {
    try {
      final userId = await supabaseAuth.getUser();
      final profileId = userId.user?.id;
      if (profileId == null || profileId.isEmpty) {
        throw Exception('Authenticated user profile was not found');
      }

      await _supabase
          .from('profiles')
          .update({'purpose': purpose.trim()})
          .eq('id', profileId);
    } catch (e, st) {
      debugPrint('Error updating purpose: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  /// Columns a student may edit on their own profile (the database grants
  /// update on these only; see 20261001000000_production_security.sql).
  static const editableDetailColumns = {
    'first_name',
    'middle_name',
    'last_name',
    'username',
    'university',
    'age',
    'bio',
    'profile_image',
  };

  static const _avatarBucket = 'avatars';

  @override
  Future<void> removeProfileImage() async {
    try {
      final userId = await supabaseAuth.getUser();
      final profileId = userId.user?.id;
      if (profileId == null || profileId.isEmpty) {
        throw Exception('Authenticated user profile was not found');
      }

      // The profile stops pointing at the picture first, so a failed file
      // deletion can never leave a broken link behind.
      await _supabase
          .from('profiles')
          .update({'profile_image': null})
          .eq('id', profileId);
      try {
        await _supabase.storage.from(_avatarBucket).remove([
          '$profileId/avatar.jpg',
        ]);
      } catch (e) {
        debugPrint('Profile image file was not deleted: $e');
      }
    } catch (e, st) {
      debugPrint('Error removing profile image: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  @override
  Future<String> uploadProfileImage(Uint8List jpegBytes) async {
    try {
      final userId = await supabaseAuth.getUser();
      final profileId = userId.user?.id;
      if (profileId == null || profileId.isEmpty) {
        throw Exception('Authenticated user profile was not found');
      }

      final path = '$profileId/avatar.jpg';
      final storage = _supabase.storage.from(_avatarBucket);
      await storage.uploadBinary(
        path,
        jpegBytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );
      // The path never changes, so a version suffix makes devices fetch the
      // new picture instead of showing a cached one.
      final url =
          '${storage.getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
      await _supabase
          .from('profiles')
          .update({'profile_image': url})
          .eq('id', profileId);
      return url;
    } catch (e, st) {
      debugPrint('Error uploading profile image: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  @override
  Future<void> updateDetails(Map<String, Object?> fields) async {
    try {
      final unknown = fields.keys.where(
        (key) => !editableDetailColumns.contains(key),
      );
      if (unknown.isNotEmpty) {
        throw ArgumentError(
          'Profile fields not editable: ${unknown.join(', ')}',
        );
      }
      final userId = await supabaseAuth.getUser();
      final profileId = userId.user?.id;
      if (profileId == null || profileId.isEmpty) {
        throw Exception('Authenticated user profile was not found');
      }

      await _supabase.from('profiles').update(fields).eq('id', profileId);
    } catch (e, st) {
      debugPrint('Error updating profile details: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  /// Saves the board exam date on the profile (`date_of_examination`, one of
  /// the columns clients may update). Stored as local midnight of the chosen
  /// day, in UTC, which the screen converts back with toLocal().
  @override
  Future<void> updateExamDate(DateTime date) async {
    try {
      final userId = await supabaseAuth.getUser();
      final profileId = userId.user?.id;
      if (profileId == null || profileId.isEmpty) {
        throw Exception('Authenticated user profile was not found');
      }
      final day = DateTime(date.year, date.month, date.day).toUtc();

      await _supabase
          .from('profiles')
          .update({'date_of_examination': day.toIso8601String()})
          .eq('id', profileId);
    } catch (e, st) {
      debugPrint('Error updating exam date: $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }
}
