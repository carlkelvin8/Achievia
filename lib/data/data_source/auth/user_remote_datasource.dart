// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:achievia/core/di/injection.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:achievia/const.dart';
import 'package:achievia/core/di/local_storage_service.dart';
import 'package:achievia/data/models/auth/user_dto.dart';

abstract class UserRepositoryDataSource {
  Future<UserDto> login(UserDto dto);
  Future<UserDto> getProfile(String token);
}

@injectable
@lazySingleton
class UserRemoteDatasource implements UserRepositoryDataSource {
  final Dio dio;
  UserRemoteDatasource({required this.dio});

  @override
  Future<UserDto> login(UserDto dto) async {
    final LocalStorageService storageService = sl<LocalStorageService>();
    try {
      final response = await dio.post(
        '$BASE_URL/auth/login',
        data: dto.toJson(),
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: response.data['message'] ?? 'Login failed',
        );
      }

      await storageService.saveToken(response.data['data']['token'], jsonEncode(response.data['data']['user']['id']));
      final token = storageService.token;
      final userId = storageService.creds;
      print(userId);
      print(token);
      return UserDto.fromJson(response.data['data']);
    } on DioException catch(e){
      print(e.response?.data);
      return UserDto.fromJson({});
    }
    
    
    catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserDto> getProfile(String token) async {
    try {
      final response = await dio.get(
        '$BASE_URL/you/profile',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        if (data != null && data['data'] != null) {
          return UserDto.fromJson(data['data']);
        }
        return UserDto.fromJson(data);
      }

      return UserDto.fromJson({});
    } catch (e, st) {
      print('Error fetching profile: $e');
      print('Stack trace: $st');
      return UserDto.fromJson({});
    }
  }
}
