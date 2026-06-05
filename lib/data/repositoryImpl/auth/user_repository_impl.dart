// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/data/models/auth/user_dto.dart';
import 'package:injectable/injectable.dart';

import 'package:achievia/data/data_source/auth/user_remote_datasource.dart';
import 'package:achievia/domain/entities/api/auth/user_entity.dart';
import 'package:achievia/domain/repository/auth/user_repository.dart';

@injectable
@lazySingleton
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDatasource datasource;
  UserRepositoryImpl({required this.datasource});

  @override
  Future<UserEntity> loginRepository(UserEntity dto) async {
    final entity = UserDto.fromEntity(dto);
    final data = await datasource.login(entity);
    return data.toEntity();
  }

  @override
  Future<UserEntity> getProfile(String token) async {
    final data = await datasource.getProfile(token);
    return data.toEntity();
  }

  @override
  Future<UserEntity> signUpRepository(UserEntity dto) async {
    final entity = UserDto.fromEntity(dto);
    final data = await datasource.signUp(entity);
    return data.toEntity();
  }

  @override
  Future<void> sendResetEmail(String email) async {
    await datasource.resetPasswordSend(email);
  }

  @override
  Future<void> validateOtp(String code, String email) async {
    await datasource.validateOtp(code, email);
  }

  @override
  Future<void> changePassword(String password) async {
    await datasource.changePassword(password);
  }
}
