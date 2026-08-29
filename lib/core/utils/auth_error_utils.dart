import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

const emailAlreadyExistsMessage =
    'Email already exists. Please use another email.';

String userFacingAuthError(Object error) {
  var message = error is AuthException ? error.message : error.toString();
  message = message.trim();

  try {
    final decoded = jsonDecode(message);
    if (decoded is Map && decoded['message'] is String) {
      message = (decoded['message'] as String).trim();
    }
  } on FormatException {
    // Supabase normally returns plain text, so the original message is fine.
  }

  final normalizedMessage = message.toLowerCase();
  final authCode = error is AuthException ? error.code?.toLowerCase() : null;
  if (authCode == 'user_already_exists' ||
      normalizedMessage.contains('user already registered') ||
      normalizedMessage.contains('email already registered') ||
      normalizedMessage.contains('email already exists')) {
    return emailAlreadyExistsMessage;
  }

  if (normalizedMessage.contains('database error saving new user')) {
    return 'We could not save your profile. Your username may already be in use; '
        'please choose another username and try again.';
  }

  return message.isEmpty ? 'Something went wrong. Please try again.' : message;
}
