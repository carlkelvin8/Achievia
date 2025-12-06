// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:achievia/const.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:achievia/data/models/auth/user_dto.dart';
abstract class UserRepositoryDataSource {
  Future<UserDto> login(UserDto dto);
  
}

@injectable
@lazySingleton
class UserRemoteDatasource implements UserRepositoryDataSource {
  final Dio dio;
  UserRemoteDatasource({
    required this.dio,
  });
  
  @override
  Future<UserDto> login(UserDto dto) async {
    try {
      final response = await dio.post('$BASE_URL/auth/login', 
      data: dto.toJson(),
      options: Options(
        sendTimeout: Duration(milliseconds: 1000),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }
      )
      );
      if (response.statusCode != 200 || response.statusCode != 201) {
        final message =  UserDto.fromJson(response.data['message']);
        return message;
      }
      final token =  UserDto.fromJson(response.data['data']['token']);
      return token;
    } catch (e, st) {
      print(e);
      print('stack trace: $st');
      return UserDto.fromJson({});
    }
  }
  
}
