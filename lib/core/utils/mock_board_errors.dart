import 'dart:async';

import 'package:achievia/core/utils/auth_error_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Why Mock Boards could not be prepared. Each value maps to one safe,
/// user-facing message; the technical detail only goes to the debug log.
enum MockBoardFailure {
  /// The Question Bank has no (complete) Mock Board setup, e.g. a subtopic
  /// without a configured question count.
  notConfigured,

  /// A section does not have enough eligible questions.
  notEnoughQuestions,

  /// No connection or DNS failure.
  network,

  /// Preparing the board took too long (the connection works but is slow).
  timeout,

  /// The signed-in user is not allowed to read the Question Bank.
  permission,

  /// Anything else.
  internal,
}

/// A Mock Board generation failure with a known cause. It is a [StateError] so
/// existing handlers keep working.
class MockBoardException extends StateError {
  MockBoardException(this.failure, super.message);

  final MockBoardFailure failure;
}

MockBoardFailure classifyMockBoardError(Object error) {
  if (error is MockBoardException) return error.failure;
  if (error is TimeoutException) return MockBoardFailure.timeout;
  if (isNetworkError(error)) return MockBoardFailure.network;
  if (error is PostgrestException) {
    final code = error.code ?? '';
    if (code == '42501' ||
        code == '401' ||
        code == '403' ||
        code == 'PGRST301') {
      return MockBoardFailure.permission;
    }
  }
  if (error is AuthException) return MockBoardFailure.permission;
  return MockBoardFailure.internal;
}

/// Never contains URLs, SQL, identifiers or exception text.
String mockBoardUserMessage(MockBoardFailure failure) => switch (failure) {
  MockBoardFailure.notConfigured || MockBoardFailure.notEnoughQuestions =>
    'Mock Boards are not available yet. The question bank is still being '
        'prepared.',
  MockBoardFailure.network => networkErrorMessage,
  MockBoardFailure.timeout =>
    'Preparing your Mock Board is taking too long. Please try again.',
  MockBoardFailure.permission =>
    'You do not have access to Mock Boards right now. Please sign in again.',
  MockBoardFailure.internal =>
    'Mock Boards could not be prepared. Please try again later.',
};
