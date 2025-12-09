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
  UserRepositoryImpl({
    required this.datasource,
  });
  
  @override
  Future<UserEntity> loginRepository(UserEntity dto) async{
    final entity =  UserDto.fromEntity(dto);
    final data = await datasource.login(entity);
    return data.toEntity();
  }
  
}
