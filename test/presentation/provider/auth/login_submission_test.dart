import 'dart:async';

import 'package:achievia/core/utils/auth_error_utils.dart';
import 'package:achievia/domain/entities/api/auth/user_entity.dart';
import 'package:achievia/domain/use_cases/auth/user_use_case.dart';
import 'package:achievia/presentation/provider/auth/event/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class _LoginUseCase implements UserUseCase {
  int calls = 0;
  Completer<UserEntity> pending = Completer<UserEntity>();
  @override
  Future<UserEntity> getLogin(UserEntity entity) {
    calls++;
    return pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'concurrent login submits once; failed request releases the retry guard',
    () async {
      final useCase = _LoginUseCase();
      final container = ProviderContainer(
        overrides: [userUseCaseProvider.overrideWithValue(useCase)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(loginFormProvider.notifier);
      notifier.emailControllerLogin.text = 'user@example.test';
      notifier.passwordController.text = ' password with spaces ';
      final first = notifier.submit();
      expect(await notifier.submit(), isFalse);
      expect(useCase.calls, 1);
      useCase.pending.completeError(
        const AuthException('Invalid login credentials'),
      );
      expect(await first, isFalse);
      expect(container.read(loginFormProvider).isLoading, isFalse);
      useCase.pending = Completer<UserEntity>();
      final retry = notifier.submit();
      expect(useCase.calls, 2);
      useCase.pending.complete(UserEntity());
      expect(await retry, isTrue);
      expect(notifier.passwordController.text, isEmpty);
    },
  );

  test('a failed host lookup shows the connection message, not the URL', () async {
    final useCase = _LoginUseCase();
    final container = ProviderContainer(
      overrides: [userUseCaseProvider.overrideWithValue(useCase)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(loginFormProvider.notifier);
    notifier.emailControllerLogin.text = 'user@example.test';
    notifier.passwordController.text = 'password';
    final result = notifier.submit();
    useCase.pending.completeError(
      http.ClientException(
        "SocketException: Failed host lookup: 'bcxvjfxrdfzqzmoseegx.supabase.co'",
        Uri.parse(
          'https://bcxvjfxrdfzqzmoseegx.supabase.co/auth/v1/token?grant_type=password',
        ),
      ),
    );

    expect(await result, isFalse);
    final state = container.read(loginFormProvider);
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, networkErrorMessage);
    expect(state.errorMessage, isNot(contains('supabase')));
  });
}
