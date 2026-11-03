import 'dart:async';
import 'dart:io';

import 'package:achievia/core/utils/auth_error_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

const host = 'bcxvjfxrdfzqzmoseegx.supabase.co';

void main() {
  final lookupFailure = http.ClientException(
    "SocketException: Failed host lookup: '$host' "
    '(OS Error: No address associated with hostname, errno = 7), '
    'uri=https://$host/auth/v1/token?grant_type=password',
    Uri.parse('https://$host/auth/v1/token?grant_type=password'),
  );

  group('network failures', () {
    final cases = <String, Object>{
      'the production ClientException (failed host lookup)': lookupFailure,
      'a bare SocketException': SocketException("Failed host lookup: '$host'"),
      'a refused connection': const SocketException('Connection refused'),
      'supabase retryable fetch failure': AuthRetryableFetchException(
        message: lookupFailure.toString(),
      ),
    };

    cases.forEach((name, error) {
      test('$name shows the safe connection message', () {
        expect(isNetworkError(error), isTrue);
        final message = userFacingAuthError(error);
        expect(message, networkErrorMessage);
        expect(message.toLowerCase(), isNot(contains('supabase')));
        expect(message, isNot(contains(host)));
        expect(message.toLowerCase(), isNot(contains('socket')));
        expect(message.toLowerCase(), isNot(contains('exception')));
      });
    });

    test('the message is the agreed wording', () {
      expect(
        networkErrorMessage,
        'Unable to connect to the server. Please check your internet '
        'connection and try again.',
      );
    });
  });

  group('timeouts', () {
    test('a TimeoutException says the request timed out', () {
      final error = TimeoutException('request took too long');
      expect(classifyAuthFailure(error), AuthFailure.timeout);
      expect(isNetworkError(error), isTrue);
      expect(userFacingAuthError(error), timeoutErrorMessage);
    });

    test('a client-side fetch timeout is a timeout, not offline', () {
      final error = AuthRetryableFetchException(
        message: 'Connection timed out, errno = 110',
      );
      expect(userFacingAuthError(error), timeoutErrorMessage);
    });
  });

  group('server answered with an error (not a network failure)', () {
    test('HTTP 500 from a failing signup trigger is a profile failure', () {
      final error = AuthRetryableFetchException(
        message:
            '{"code":500,"error_code":"unexpected_failure",'
            '"msg":"Database error saving new user"}',
        statusCode: '500',
      );
      expect(classifyAuthFailure(error), AuthFailure.profileCreation);
      expect(isNetworkError(error), isFalse);
      expect(isEmailFailure(error), isFalse);
      expect(userFacingAuthError(error), profileCreationErrorMessage);
    });

    test('other 5xx responses say the server is unavailable', () {
      final error = AuthRetryableFetchException(
        message: '<html>Bad gateway</html>',
        statusCode: '502',
      );
      expect(isNetworkError(error), isFalse);
      expect(userFacingAuthError(error), serverUnavailableMessage);
    });

    test('a 5xx PostgrestException is server unavailable', () {
      const error = PostgrestException(message: 'boom', code: '503');
      expect(userFacingAuthError(error), serverUnavailableMessage);
    });
  });

  group('email failures', () {
    test('duplicate email by error code', () {
      final error = AuthApiException(
        'x',
        statusCode: '422',
        code: 'user_already_exists',
      );
      expect(isEmailFailure(error), isTrue);
      expect(userFacingAuthError(error), emailAlreadyExistsMessage);
    });

    test('invalid email by error code and by message', () {
      final byCode = AuthApiException(
        'Email address "a@b" is invalid',
        statusCode: '400',
        code: 'email_address_invalid',
      );
      const byMessage = AuthException('Unable to validate email address');
      for (final error in [byCode, byMessage]) {
        expect(isEmailFailure(error), isTrue);
        expect(userFacingAuthError(error), invalidEmailMessage);
      }
    });

    test('unrelated failures never target the email field', () {
      final errors = <Object>[
        TimeoutException('t'),
        const AuthException('Username is already taken.'),
        const AuthException('Password should be at least 6 characters'),
        AuthApiException(
          'x',
          statusCode: '429',
          code: 'over_email_send_rate_limit',
        ),
        http.ClientException('Failed host lookup'),
      ];
      for (final error in errors) {
        expect(isEmailFailure(error), isFalse, reason: '$error');
      }
    });
  });

  group('safe handling', () {
    test('rate limits get their own message', () {
      final error = AuthApiException(
        'x',
        statusCode: '429',
        code: 'over_email_send_rate_limit',
      );
      expect(userFacingAuthError(error), rateLimitedMessage);
    });

    test('unknown non-auth errors never leak raw text', () {
      expect(
        userFacingAuthError(StateError('secret internals')),
        genericAuthErrorMessage,
      );
    });

    test('redactSecrets strips keys, passwords and tokens', () {
      final out = redactSecrets(
        'apikey: sb_publishable_abc password=hunter2 Bearer eyJhbGci.x.y',
      );
      expect(out, isNot(contains('sb_publishable_abc')));
      expect(out, isNot(contains('hunter2')));
      expect(out, isNot(contains('eyJhbGci')));
    });
  });

  group('real authentication failures are not mislabeled', () {
    test('wrong credentials keep their own message', () {
      const error = AuthException('Invalid login credentials');
      expect(isNetworkError(error), isFalse);
      expect(userFacingAuthError(error), 'Invalid login credentials');
    });

    test('duplicate email keeps its dedicated message', () {
      expect(
        userFacingAuthError(const AuthException('User already registered')),
        emailAlreadyExistsMessage,
      );
    });

    test('an empty message falls back to the generic text', () {
      expect(
        userFacingAuthError(const AuthException('')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
