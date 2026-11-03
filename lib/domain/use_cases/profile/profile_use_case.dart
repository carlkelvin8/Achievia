import 'dart:typed_data';

import 'package:achievia/data/repositoryImpl/profile/profile_repository_impl.dart';
import 'package:achievia/domain/entities/api/profile/profile_entity.dart';
import 'package:injectable/injectable.dart';

@injectable
class ProfileUseCase {
  final ProfileRepositoryImpl impl;

  ProfileUseCase({required this.impl});

  Future<ProfileEntity> getProfile() async => await impl.getProfile();

  Future<String> updateMantra(String mantra) async =>
      await impl.updateMantra(mantra);

  Future<void> updatePurpose(String purpose) async =>
      await impl.updatePurpose(purpose);

  Future<void> updateExamDate(DateTime date) async =>
      await impl.updateExamDate(date);

  Future<void> updateDetails(Map<String, Object?> fields) async =>
      await impl.updateDetails(fields);

  Future<void> removeProfileImage() async => await impl.removeProfileImage();

  Future<String> uploadProfileImage(Uint8List jpegBytes) async =>
      await impl.uploadProfileImage(jpegBytes);
}
