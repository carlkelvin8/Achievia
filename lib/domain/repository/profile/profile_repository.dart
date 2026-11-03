import 'dart:typed_data';

import 'package:achievia/domain/entities/api/profile/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getProfile();
  Future<String> updateMantra(String mantra);
  Future<void> updatePurpose(String purpose);
  Future<void> updateExamDate(DateTime date);
  Future<void> updateDetails(Map<String, Object?> fields);
  Future<String> uploadProfileImage(Uint8List jpegBytes);
  Future<void> removeProfileImage();
}
