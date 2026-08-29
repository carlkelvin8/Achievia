// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/domain/entities/api/auth/user_entity.dart';

class SignupResult {
  final UserEntity user;
  final bool requiresEmailConfirmation;

  SignupResult({
    required this.user,
    required this.requiresEmailConfirmation,
  });
}
