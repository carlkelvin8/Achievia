// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/const.dart';
import 'package:achievia/core/utils/auth_error_utils.dart';
import 'package:achievia/data/models/auth/signup_result_dto.dart';
import 'package:achievia/data/models/auth/user_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class UserRepositoryDataSource {
  Future<UserDto> login(UserDto dto);
  Future<UserDto> getProfile(String token);
  Future<SignupResultDto> signUp(UserDto dto);
  Future<void> resetPasswordSend(String email);
  Future<void> validateOtp(String code, String email);
  Future<void> changePassword(String password);
}

@injectable
@lazySingleton
class UserRemoteDatasource implements UserRepositoryDataSource {
  UserRemoteDatasource();

  static const signupTimeout = Duration(seconds: 30);

  Future<bool?> _checkUsernameAvailability(String username) async {
    try {
      final response = await supabase.rpc(
        'is_username_available',
        params: {'p_username': username},
      );
      if (response is bool) {
        return response;
      }
      return response.toString().toLowerCase() == 'true';
    } on PostgrestException catch (e) {
      // Keep signup usable while an older deployment is waiting for the
      // forward migration. The database unique constraint remains final.
      if (e.code == 'PGRST202' || e.code == '42883') {
        debugPrint(e.toString());
        return null;
      }
      logAuthFailure('signup.username_check', e);
      rethrow;
    }
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

  @visibleForTesting
  static UserDto buildSignupFallback(UserDto dto) {
    final metadata = Map<String, dynamic>.from(dto.toJson())
      ..remove('password')
      ..remove('token');
    return UserDto.fromJson(metadata);
  }

  /// Signs in with the password exactly as typed. Accounts created before
  /// passwords stopped being trimmed were stored without surrounding
  /// whitespace, so on rejected credentials the trimmed form is tried once.
  Future<AuthResponse> _signIn(String? email, String password) async {
    try {
      return await supabaseAuth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthApiException catch (e) {
      final trimmed = password.trim();
      final rejected =
          e.code == 'invalid_credentials' ||
          e.message.toLowerCase().contains('invalid login credentials');
      if (!rejected || trimmed == password || trimmed.isEmpty) rethrow;
      return supabaseAuth.signInWithPassword(email: email, password: trimmed);
    }
  }

  @override
  Future<UserDto> login(UserDto dto) async {
    try {
      final res = await _signIn(dto.username?.trim(), dto.password!);
      final session = res.session;
      final user = res.user;

      if (session == null || session.isExpired) {
        throw AuthException('User not found');
      }
      if (user?.emailConfirmedAt == null) {
        throw AuthException('User is not verified yet');
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
  Future<SignupResultDto> signUp(UserDto dto) async {
    final username = dto.username?.trim() ?? '';
    if (username.isEmpty) {
      throw AuthException('Username is required.');
    }

    final usernameAvailable = await _checkUsernameAvailability(username);
    if (usernameAvailable == false) {
      throw AuthException(
        'Username is already taken. Please choose another username.',
      );
    }

    final metadata = Map<String, dynamic>.from(dto.toJson())
      ..remove('password')
      ..remove('token');
    metadata['username'] = username;

    final AuthResponse auth;
    try {
      auth = await supabaseAuth
          .signUp(
            password: dto.password!,
            email: dto.email!.trim(),
            data: metadata,
            emailRedirectTo: supabaseAuthRedirectUrl,
          )
          .timeout(signupTimeout);
    } catch (e, st) {
      logAuthFailure('signup.auth', e, st);
      rethrow;
    }

    final user = auth.user;
    if (user == null) {
      throw AuthException('Unable to create the account.');
    }

    if (isDuplicateEmailResponse(auth)) {
      throw const AuthException(
        emailAlreadyExistsMessage,
        code: 'user_already_exists',
      );
    }

    return SignupResultDto(
      user: _fromUserMetadata(user, buildSignupFallback(dto)),
      requiresEmailConfirmation: auth.session == null,
    );
  }

  @visibleForTesting
  static bool isDuplicateEmailResponse(AuthResponse response) {
    final user = response.user;
    return response.session == null &&
        user != null &&
        user.identities?.isEmpty == true;
  }

  @override
  Future<void> resetPasswordSend(String email) async {
    try {
      await supabaseAuth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      debugPrint(e.toString());
      rethrow;
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
      await supabaseAuth.updateUser(UserAttributes(password: password));
    } on AuthException catch (e) {
      debugPrint(e.toString());
      rethrow;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
}
