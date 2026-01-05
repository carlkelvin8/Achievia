import 'package:achievia/domain/entities/api/auth/user_entity.dart';

abstract class UserRepository {
  Future<UserEntity> loginRepository(UserEntity dto);
  Future<UserEntity> getProfile(String token);
}
