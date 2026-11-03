import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const emailAlreadyExistsMessage =
    'Email already exists. Please use another email.';

const networkErrorMessage =
    'Unable to connect to the server. Please check your internet connection '
    'and try again.';

const timeoutErrorMessage = 'The request timed out. Please try again.';
const invalidEmailMessage = 'Please enter a valid email address.';
const profileCreationErrorMessage =
    'Your account could not be set up. Please try again, and contact support '
    'if it keeps happening.';
const serverUnavailableMessage =
    'The server is temporarily unavailable. Please try again in a few minutes.';
const rateLimitedMessage =
    'Too many attempts. Please wait a moment and try again.';
const genericAuthErrorMessage = 'Something went wrong. Please try again.';

/// What actually went wrong with an auth request, so each cause gets its own
/// message and only email problems paint the email field red.
enum AuthFailure {
  offline,
  timeout,
  emailTaken,
  invalidEmail,
  weakPassword,
  rateLimited,
  profileCreation,
  serverUnavailable,
  rejected,
  unknown,
}

const _networkMarkers = [
  'socketexception',
  'clientexception',
  'handshakeexception',
  'failed host lookup',
  'network is unreachable',
  'connection refused',
  'connection reset',
  'connection closed',
  'no address associated with hostname',
];

bool _isTimeoutText(String text) =>
    text.contains('timed out') || text.contains('timeoutexception');

AuthFailure classifyAuthFailure(Object error) {
  if (error is TimeoutException) return AuthFailure.timeout;
  final text = '${error.runtimeType} $error'.toLowerCase();

  if (error is AuthRetryableFetchException) {
    // gotrue wraps every HTTP 5xx in this type, so a status code means the
    // server answered. No status code means the request never completed.
    final status = int.tryParse(error.statusCode ?? '');
    if (status == null) {
      return _isTimeoutText(text) ? AuthFailure.timeout : AuthFailure.offline;
    }
    if (text.contains('database error saving new user')) {
      return AuthFailure.profileCreation;
    }
    return AuthFailure.serverUnavailable;
  }

  if (error is AuthException) {
    final code = error.code?.toLowerCase();
    final message = error.message.toLowerCase();
    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        message.contains('user already registered') ||
        message.contains('email already registered') ||
        message.contains('email already exists')) {
      return AuthFailure.emailTaken;
    }
    if (code == 'email_address_invalid' ||
        message.contains('unable to validate email address') ||
        message.contains('invalid email') ||
        (message.contains('email address') && message.contains('is invalid'))) {
      return AuthFailure.invalidEmail;
    }
    if (error is AuthWeakPasswordException || code == 'weak_password') {
      return AuthFailure.weakPassword;
    }
    if (code == 'over_email_send_rate_limit' ||
        code == 'over_request_rate_limit' ||
        message.contains('rate limit')) {
      return AuthFailure.rateLimited;
    }
    if (message.contains('database error saving new user')) {
      return AuthFailure.profileCreation;
    }
    return AuthFailure.rejected;
  }

  if (error is PostgrestException) {
    final status = int.tryParse(error.code ?? '');
    return status != null && status >= 500
        ? AuthFailure.serverUnavailable
        : AuthFailure.unknown;
  }

  if (_isTimeoutText(text)) return AuthFailure.timeout;
  if (_networkMarkers.any(text.contains)) return AuthFailure.offline;
  return AuthFailure.unknown;
}

/// True when no server answer was received: no DNS, no route, refused or
/// reset connection, TLS handshake failure or a timeout. A server that
/// answered with an error (even a 5xx) is NOT a network error.
bool isNetworkError(Object error) {
  final failure = classifyAuthFailure(error);
  return failure == AuthFailure.offline || failure == AuthFailure.timeout;
}

/// Failures that belong to the email field.
bool isEmailFailure(Object error) {
  final failure = classifyAuthFailure(error);
  return failure == AuthFailure.emailTaken ||
      failure == AuthFailure.invalidEmail;
}

/// Development-only diagnostics: the failing operation, exception type, status
/// and message. Secrets are redacted and nothing is logged in release builds.
void logAuthFailure(String operation, Object error, [StackTrace? stack]) {
  if (!kDebugMode) return;
  final status = switch (error) {
    AuthException(:final statusCode) => statusCode,
    PostgrestException(:final code) => code,
    _ => null,
  };
  debugPrint(
    '[auth] op=$operation type=${error.runtimeType} '
    'class=${classifyAuthFailure(error).name} status=$status '
    'message=${redactSecrets(error.toString())}',
  );
  if (stack != null) debugPrint(redactSecrets(stack.toString()));
}

@visibleForTesting
String redactSecrets(String text) => text.replaceAllMapped(
  RegExp(
    r'(apikey|password|access_token|refresh_token|authorization|bearer)'
    r'''(["'=: ]+)[^\s"',}&]+''',
    caseSensitive: false,
  ),
  (m) => '${m[1]}${m[2]}<redacted>',
);

/// Safe message for any failed operation (not only auth). Use this instead of
/// rendering `error.toString()`, which can expose table, column or URL details.
String userFacingError(Object error) {
  // Our own validation errors carry a message written for the user.
  if (error is ArgumentError && error.message is String) {
    final message = (error.message as String).trim();
    if (message.isNotEmpty) return message;
  }
  return userFacingAuthError(error);
}

/// Message that is safe to show to end users: never contains the Supabase
/// URL, a stack or raw exception text for connectivity or server problems.
String userFacingAuthError(Object error) {
  switch (classifyAuthFailure(error)) {
    case AuthFailure.offline:
      return networkErrorMessage;
    case AuthFailure.timeout:
      return timeoutErrorMessage;
    case AuthFailure.emailTaken:
      return emailAlreadyExistsMessage;
    case AuthFailure.invalidEmail:
      return invalidEmailMessage;
    case AuthFailure.rateLimited:
      return rateLimitedMessage;
    case AuthFailure.profileCreation:
      return profileCreationErrorMessage;
    case AuthFailure.serverUnavailable:
      return serverUnavailableMessage;
    case AuthFailure.weakPassword:
    case AuthFailure.rejected:
    case AuthFailure.unknown:
      break;
  }

  // Never surface raw exception text for non-auth errors.
  if (error is! AuthException) return genericAuthErrorMessage;

  var message = error.message.trim();
  try {
    final decoded = jsonDecode(message);
    if (decoded is Map && decoded['message'] is String) {
      message = (decoded['message'] as String).trim();
    }
  } on FormatException {
    // Supabase normally returns plain text, so the original message is fine.
  }
  return message.isEmpty ? genericAuthErrorMessage : message;
}
