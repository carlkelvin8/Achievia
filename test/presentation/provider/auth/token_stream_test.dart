import 'dart:async';

import 'package:achievia/presentation/provider/auth/event/token_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

AuthState signedIn(String token) => AuthState(
  AuthChangeEvent.tokenRefreshed,
  Session(
    accessToken: token,
    tokenType: 'bearer',
    user: const User(
      id: 'user-1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
    ),
  ),
);

void main() {
  test('a failed token refresh does not end the token stream', () async {
    final events = StreamController<AuthState>.broadcast();
    final emitted = <Object?>[];
    final errors = <Object>[];
    final sub = accessTokens(
      initial: 'first',
      events: events.stream,
    ).listen(emitted.add, onError: errors.add);
    addTearDown(() {
      sub.cancel();
    });

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    events.addError(AuthRetryableFetchException(message: 'Failed host lookup'));
    await settle();
    events.add(signedIn('second'));
    await settle();
    events.addError(AuthRetryableFetchException(message: 'still offline'));
    await settle();
    events.add(signedIn('third'));
    await settle();

    expect(errors, isEmpty);
    expect(emitted, ['first', 'second', 'third']);
  });

  test('sign-out emits a null token', () async {
    final events = StreamController<AuthState>.broadcast();
    final emitted = <String?>[];
    final sub = accessTokens(
      initial: 'a',
      events: events.stream,
    ).listen(emitted.add);
    addTearDown(() {
      sub.cancel();
    });

    await Future<void>.delayed(Duration.zero);
    events.add(const AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(Duration.zero);

    expect(emitted, ['a', null]);
  });
}
