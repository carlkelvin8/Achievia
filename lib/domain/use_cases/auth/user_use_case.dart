// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/domain/entities/api/auth/user_entity.dart';
import 'package:injectable/injectable.dart';

import 'package:achievia/data/repositoryImpl/auth/user_repository_impl.dart';

@injectable
class UserUseCase {
  final UserRepositoryImpl impl;
  UserUseCase({required this.impl});

  Future<UserEntity> getLogin(UserEntity entity) async =>
      await impl.loginRepository(entity);

  Future<UserEntity> getSignup(UserEntity entity) async =>
      await impl.signUpRepository(entity);

  Future<UserEntity> getProfile(String token) async =>
      await impl.getProfile(token);

  Future<void> sendResetPasswordToEmail(String email) async =>
      await impl.sendResetEmail(email);
}
