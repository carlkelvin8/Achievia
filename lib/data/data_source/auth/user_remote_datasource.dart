// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/data/models/auth/user_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class UserRepositoryDataSource {
  Future<UserDto> login(UserDto dto);
  Future<UserDto> getProfile(String token);
  Future<UserDto> signUp(UserDto dto);
}

@injectable
@lazySingleton
class UserRemoteDatasource implements UserRepositoryDataSource {
  UserRemoteDatasource();

  String _requiredEmail(UserDto dto) {
    final email = dto.email?.trim();
    if (email != null && email.isNotEmpty) return email;

    final username = dto.username?.trim();
    if (username != null && username.isNotEmpty) return username;

    throw Exception('Email is required');
  }

  UserDto _fromUserMetadata(User? user, UserDto fallback) {
    final metadata = user?.userMetadata;
    final nestedData = metadata?['data'];
    if (nestedData is Map) {
      return UserDto.fromJson(Map<String, dynamic>.from(nestedData));
    }
    if (metadata != null && metadata.isNotEmpty) {
      return UserDto.fromJson(Map<String, dynamic>.from(metadata));
    }
    return UserDto.fromJson(fallback.toJson());
  }

  @override
  Future<UserDto> login(UserDto dto) async {
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _requiredEmail(dto),
        password: dto.password!.trim(),
      );
      final session = res.session;
      final user = res.user;

      if (session == null || session.isExpired) {
        throw Exception("User not found");
      }
      if (user?.emailConfirmedAt == null) {
        throw Exception('User is not verified yet');
      }
      return _fromUserMetadata(user, dto);
    } on AuthApiException catch (e) {
      debugPrint(e.toString());
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserDto> getProfile(String token) async {
    try {
      final response = await Supabase.instance.client.auth.getUser();

      if (response.user!.isAnonymous) {
        throw Exception("This user is anonymous");
      }
      return _fromUserMetadata(response.user, UserDto.fromJson({}));
    } catch (e) {
      return UserDto.fromJson({});
    }
  }

  @override
  Future<UserDto> signUp(UserDto dto) async {
    try {
      final auth = await Supabase.instance.client.auth.signUp(
        password: dto.password!.trim(),
        email: _requiredEmail(dto),
        data: dto.toJson(),
      );
      if (auth.session == null) {
        return UserDto.fromJson({});
      }
      return UserDto.fromJson({});
    } catch (e) {
      return UserDto.fromJson({});
    }
  }
}
