// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/data/models/auth/user_dto.dart';
import 'package:achievia/domain/entities/api/auth/signup_result.dart';

class SignupResultDto {
  final UserDto user;
  final bool requiresEmailConfirmation;

  SignupResultDto({
    required this.user,
    required this.requiresEmailConfirmation,
  });

  SignupResult toEntity() => SignupResult(
    user: user.toEntity(),
    requiresEmailConfirmation: requiresEmailConfirmation,
  );

  static SignupResultDto fromEntity(SignupResult entity) => SignupResultDto(
    user: UserDto.fromEntity(entity.user),
    requiresEmailConfirmation: entity.requiresEmailConfirmation,
  );
}
