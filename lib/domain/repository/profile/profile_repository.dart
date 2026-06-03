import 'package:achievia/domain/entities/api/profile/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getProfile();
  Future<String> updateMantra(String mantra);
}
