import 'package:achievia/domain/entities/api/auth/signup_result.dart';
import 'package:achievia/domain/entities/api/auth/user_entity.dart';

abstract class UserRepository {
  Future<UserEntity> loginRepository(UserEntity dto);
  Future<SignupResult> signUpRepository(UserEntity dto);
  Future<UserEntity> getProfile(String token);
  Future<void> sendResetEmail(String email);
  Future<void> validateOtp(String code, String email);
  Future<void> changePassword(String password);
}
