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
}
