// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/const.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/data/models/auth/user_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class UserRepositoryDataSource {
  Future<UserDto> login(UserDto dto);
  Future<UserDto> getProfile(String token);
  Future<UserDto> signUp(UserDto dto);
  Future<void> resetPasswordSend(String email);
  Future<void> validateOtp(String code, String email);
  Future<void> changePassword(String password);
}

@injectable
@lazySingleton
class UserRemoteDatasource implements UserRepositoryDataSource {
  UserRemoteDatasource();

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
      final res = await supabaseAuth.signInWithPassword(
        email: dto.username?.trim(),
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
      debugPrint(e.toString());
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
      final auth = await supabaseAuth.signUp(
        password: dto.password!.trim(),
        email: dto.email!.trim(),
        data: dto.toJson(),
        emailRedirectTo: RouteConstants.main,
      );
      if (auth.session == null) {
        return UserDto.fromJson({});
      }
      return UserDto.fromJson({});
    } catch (e) {
      debugPrint(e.toString());
      return UserDto.fromJson({});
    }
  }

  @override
  Future<void> resetPasswordSend(String email) async {
    try {
      await supabaseAuth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      debugPrint(e.toString());
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> validateOtp(String code, String email) async {
    try {
      await supabaseAuth.verifyOTP(
        type: OtpType.recovery,
        email: email,
        token: code,
      );
    } on AuthException catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> changePassword(String password) async {
    try {
      await supabaseAuth.updateUser(UserAttributes(
        password: password.trim()
      ));
    } on AuthException catch (e) {
      debugPrint(e.toString());
      rethrow;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }

  }
}
