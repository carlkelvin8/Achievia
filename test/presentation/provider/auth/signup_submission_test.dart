import 'dart:async';

import 'package:achievia/core/utils/auth_error_utils.dart';
import 'package:achievia/domain/entities/api/auth/signup_result.dart';
import 'package:achievia/domain/entities/api/auth/user_entity.dart';
import 'package:achievia/domain/use_cases/auth/user_use_case.dart';
import 'package:achievia/presentation/provider/auth/event/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class _SignupUseCase implements UserUseCase {
  _SignupUseCase(this.outcome);
  final Future<SignupResult> Function() outcome;

  @override
  Future<SignupResult> getSignup(UserEntity entity) => outcome();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<(LoginFormState, SignupResult?)> _submit(
  Future<SignupResult> Function() outcome,
) async {
  final container = ProviderContainer(
    overrides: [userUseCaseProvider.overrideWithValue(_SignupUseCase(outcome))],
  );
  addTearDown(container.dispose);
  final notifier = container.read(loginFormProvider.notifier);
  notifier.userNameControllerSignup.text = 'tester';
  notifier.emailController.text = 'tester@example.test';
  notifier.passwordControllerSignup.text = 'password';
  final result = await notifier.submitSignup();
  return (container.read(loginFormProvider), result);
}

void main() {
  test('successful signup clears errors and returns the result', () async {
    final signup = SignupResult(
      user: UserEntity(),
      requiresEmailConfirmation: true,
    );
    final (state, result) = await _submit(() async => signup);
    expect(result, same(signup));
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, isNull);
    expect(state.emailError, isNull);
  });

  test('offline: connection message, email field not flagged', () async {
    final (state, result) = await _submit(
      () async => throw http.ClientException(
        "SocketException: Failed host lookup: 'x.supabase.co'",
      ),
    );
    expect(result, isNull);
    expect(state.errorMessage, networkErrorMessage);
    expect(state.emailError, isNull);
  });

  test('timeout: timeout message, email field not flagged', () async {
    final (state, _) = await _submit(
      () async => throw TimeoutException('slow'),
    );
    expect(state.errorMessage, timeoutErrorMessage);
    expect(state.emailError, isNull);
  });

  test('duplicate email flags the email field', () async {
    final (state, _) = await _submit(
      () async => throw AuthApiException(
        'User already registered',
        statusCode: '422',
        code: 'user_already_exists',
      ),
    );
    expect(state.errorMessage, emailAlreadyExistsMessage);
    expect(state.emailError, emailAlreadyExistsMessage);
  });

  test('invalid email flags the email field', () async {
    final (state, _) = await _submit(
      () async => throw AuthApiException(
        'Email address is invalid',
        statusCode: '400',
        code: 'email_address_invalid',
      ),
    );
    expect(state.errorMessage, invalidEmailMessage);
    expect(state.emailError, invalidEmailMessage);
  });

  test(
    'other Supabase Auth failure shows its message, not the email',
    () async {
      final (state, _) = await _submit(
        () async => throw const AuthException('Signups not allowed'),
      );
      expect(state.errorMessage, 'Signups not allowed');
      expect(state.emailError, isNull);
    },
  );

  test('profile insert failure (500) is not reported as offline', () async {
    final (state, _) = await _submit(
      () async => throw AuthRetryableFetchException(
        message: '{"msg":"Database error saving new user"}',
        statusCode: '500',
      ),
    );
    expect(state.errorMessage, profileCreationErrorMessage);
    expect(state.errorMessage, isNot(networkErrorMessage));
    expect(state.emailError, isNull);
    expect(state.isLoading, isFalse);
  });

  test('a later success clears a previous email error', () async {
    var fail = true;
    final container = ProviderContainer(
      overrides: [
        userUseCaseProvider.overrideWithValue(
          _SignupUseCase(() async {
            if (fail) {
              throw const AuthException('x', code: 'user_already_exists');
            }
            return SignupResult(
              user: UserEntity(),
              requiresEmailConfirmation: false,
            );
          }),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(loginFormProvider.notifier);
    await notifier.submitSignup();
    expect(container.read(loginFormProvider).emailError, isNotNull);
    fail = false;
    await notifier.submitSignup();
    expect(container.read(loginFormProvider).emailError, isNull);
  });
}
