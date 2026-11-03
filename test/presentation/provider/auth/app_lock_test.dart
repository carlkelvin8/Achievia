import 'package:achievia/data/data_source/auth/biometric_authenticator.dart';
import 'package:achievia/presentation/provider/auth/app_lock_provider.dart';
import 'package:achievia/presentation/widgets/overlays/app_lock_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthenticator implements BiometricAuthenticator {
  FakeAuthenticator({
    this.available = BiometricAvailability.available,
    List<BiometricOutcome> outcomes = const [],
  }) : outcomes = [...outcomes];

  BiometricAvailability available;
  final List<BiometricOutcome> outcomes;
  final reasons = <String>[];

  @override
  Future<BiometricAvailability> availability() async => available;

  @override
  Future<BiometricOutcome> authenticate(String reason) async {
    reasons.add(reason);
    return outcomes.isEmpty ? BiometricOutcome.success : outcomes.removeAt(0);
  }
}

class FakeStore implements AppLockStore {
  final values = <String, bool>{};

  @override
  bool isEnabled(String userId) => values[userId] ?? false;

  @override
  Future<void> setEnabled(String userId, bool enabled) async =>
      values[userId] = enabled;
}

class _UserId extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? id) => state = id;
}

final _userIdProvider = NotifierProvider<_UserId, String?>(_UserId.new);

class Rig {
  Rig({
    String? user,
    bool enabled = false,
    BiometricAvailability available = BiometricAvailability.available,
    List<BiometricOutcome> outcomes = const [],
  }) : authenticator = FakeAuthenticator(
         available: available,
         outcomes: outcomes,
       ),
       store = FakeStore() {
    if (user != null && enabled) store.values[user] = true;
    container = ProviderContainer(
      overrides: [
        appLockUserIdProvider.overrideWith((ref) => ref.watch(_userIdProvider)),
        appLockStoreProvider.overrideWithValue(store),
        biometricAuthenticatorProvider.overrideWithValue(authenticator),
        appLockClockProvider.overrideWithValue(() => now),
        appLockGraceProvider.overrideWithValue(const Duration(seconds: 30)),
      ],
    );
    container.read(_userIdProvider.notifier).set(user);
  }

  late final ProviderContainer container;
  final FakeAuthenticator authenticator;
  final FakeStore store;
  DateTime now = DateTime(2026, 10, 12, 9);

  AppLockState get state => container.read(appLockProvider);
  AppLockController get controller => container.read(appLockProvider.notifier);

  void dispose() => container.dispose();
}

void main() {
  group('when the lock applies', () {
    test('a cold start with the lock on begins locked', () {
      final rig = Rig(user: 'u1', enabled: true);
      addTearDown(rig.dispose);
      expect(rig.state.enabled, isTrue);
      expect(rig.state.locked, isTrue);
    });

    test('a cold start with the lock off, or signed out, is not locked', () {
      final off = Rig(user: 'u1');
      addTearDown(off.dispose);
      expect(off.state.locked, isFalse);
      final out = Rig();
      addTearDown(out.dispose);
      expect(out.state.locked, isFalse);
      expect(out.state.enabled, isFalse);
    });

    test('logging in during this run does not add a second prompt', () {
      final rig = Rig(); // signed out at start
      addTearDown(rig.dispose);
      rig.state; // build while signed out
      rig.store.values['u1'] = true;
      rig.container.read(_userIdProvider.notifier).set('u1');
      expect(rig.state.enabled, isTrue);
      expect(rig.state.locked, isFalse);
    });

    test('the lock choice belongs to the account', () {
      final rig = Rig(user: 'u1', enabled: true);
      addTearDown(rig.dispose);
      rig.container.read(_userIdProvider.notifier).set('u2');
      expect(rig.state.enabled, isFalse);
      expect(rig.state.locked, isFalse);
    });
  });

  group('background and resume', () {
    Rig unlockedRig() {
      final rig = Rig(user: 'u1', enabled: true);
      rig.controller.state = rig.state.copyWith(locked: false);
      return rig;
    }

    test('a short absence does not lock', () {
      final rig = unlockedRig();
      addTearDown(rig.dispose);
      rig.controller.onBackgrounded();
      rig.now = rig.now.add(const Duration(seconds: 10));
      rig.controller.onResumed();
      expect(rig.state.locked, isFalse);
    });

    test('an absence of the grace time or more locks again', () {
      final rig = unlockedRig();
      addTearDown(rig.dispose);
      rig.controller.onBackgrounded();
      rig.now = rig.now.add(const Duration(seconds: 30));
      rig.controller.onResumed();
      expect(rig.state.locked, isTrue);
    });

    test('a disabled lock never locks', () {
      final rig = Rig(user: 'u1');
      addTearDown(rig.dispose);
      rig.controller.onBackgrounded();
      rig.now = rig.now.add(const Duration(hours: 5));
      rig.controller.onResumed();
      expect(rig.state.locked, isFalse);
    });
  });

  group('unlock', () {
    test('a successful check unlocks', () async {
      final rig = Rig(user: 'u1', enabled: true);
      addTearDown(rig.dispose);
      expect(await rig.controller.unlock(), isTrue);
      expect(rig.state.locked, isFalse);
    });

    test('a failed check stays locked with a message', () async {
      final rig = Rig(
        user: 'u1',
        enabled: true,
        outcomes: [BiometricOutcome.failed],
      );
      addTearDown(rig.dispose);
      expect(await rig.controller.unlock(), isFalse);
      expect(rig.state.locked, isTrue);
      expect(rig.state.issue, AppLockIssue.failed);
      // Second attempt works.
      expect(await rig.controller.unlock(), isTrue);
      expect(rig.state.locked, isFalse);
    });

    test('a cancelled prompt stays locked without an error', () async {
      final rig = Rig(
        user: 'u1',
        enabled: true,
        outcomes: [BiometricOutcome.canceled],
      );
      addTearDown(rig.dispose);
      expect(await rig.controller.unlock(), isFalse);
      expect(rig.state.locked, isTrue);
      expect(rig.state.issue, AppLockIssue.none);
    });
  });

  group('turning it on and off', () {
    test('enabling needs working biometrics and a passed check', () async {
      final unsupported = Rig(
        user: 'u1',
        available: BiometricAvailability.unsupported,
      );
      addTearDown(unsupported.dispose);
      expect(
        await unsupported.controller.enable(),
        AppLockToggleResult.notAvailable,
      );
      expect(unsupported.store.values, isEmpty);

      final empty = Rig(
        user: 'u1',
        available: BiometricAvailability.notEnrolled,
      );
      addTearDown(empty.dispose);
      expect(await empty.controller.enable(), AppLockToggleResult.notEnrolled);

      final refused = Rig(user: 'u1', outcomes: [BiometricOutcome.failed]);
      addTearDown(refused.dispose);
      expect(await refused.controller.enable(), AppLockToggleResult.failed);
      expect(refused.store.values, isEmpty);
      expect(refused.state.enabled, isFalse);

      final ok = Rig(user: 'u1');
      addTearDown(ok.dispose);
      expect(await ok.controller.enable(), AppLockToggleResult.enabled);
      expect(ok.store.values['u1'], isTrue);
      expect(ok.state.enabled, isTrue);
      expect(ok.state.locked, isFalse);
    });

    test('turning it off also needs a passed check', () async {
      final rig = Rig(
        user: 'u1',
        enabled: true,
        outcomes: [BiometricOutcome.failed, BiometricOutcome.success],
      );
      addTearDown(rig.dispose);
      rig.controller.state = rig.state.copyWith(locked: false);

      expect(await rig.controller.disable(), AppLockToggleResult.failed);
      expect(rig.state.enabled, isTrue);
      expect(rig.store.values['u1'], isTrue);

      expect(await rig.controller.disable(), AppLockToggleResult.disabled);
      expect(rig.state.enabled, isFalse);
      expect(rig.store.values.containsKey('u1'), isTrue);
      expect(rig.store.values['u1'], isFalse);
    });
  });

  group('AppLockGate', () {
    Widget app(Rig rig, {required Widget child}) => UncontrolledProviderScope(
      container: rig.container,
      child: MaterialApp(home: AppLockGate(child: child)),
    );

    testWidgets('covers the app and blocks it while locked', (tester) async {
      final rig = Rig(
        user: 'u1',
        enabled: true,
        outcomes: [BiometricOutcome.canceled],
      );
      addTearDown(rig.dispose);
      var taps = 0;
      await tester.pumpWidget(
        app(
          rig,
          child: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => taps++,
                child: const Text('private'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const ValueKey('app-lock')), findsOneWidget);
      expect(find.text('Achievia is locked'), findsOneWidget);
      // The prompt was shown once, automatically.
      expect(rig.authenticator.reasons, ['Unlock Achievia']);

      await tester.tap(find.text('private'), warnIfMissed: false);
      expect(taps, 0, reason: 'taps must not reach the covered app');
    });

    testWidgets('a successful unlock reveals the app', (tester) async {
      final rig = Rig(user: 'u1', enabled: true);
      addTearDown(rig.dispose);
      await tester.pumpWidget(
        app(rig, child: const Scaffold(body: Text('private'))),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('app-lock')), findsNothing);
      expect(find.text('private'), findsOneWidget);
    });

    testWidgets('after a refused check the Unlock button tries again', (
      tester,
    ) async {
      final rig = Rig(
        user: 'u1',
        enabled: true,
        outcomes: [BiometricOutcome.failed],
      );
      addTearDown(rig.dispose);
      await tester.pumpWidget(
        app(rig, child: const Scaffold(body: Text('private'))),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('app-lock')), findsOneWidget);
      expect(find.byKey(const ValueKey('app-lock-message')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('app-lock-unlock')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('app-lock')), findsNothing);
      expect(rig.authenticator.reasons, hasLength(2));
    });

    testWidgets('leaving the app for the grace time locks it on return', (
      tester,
    ) async {
      final rig = Rig(user: 'u1', enabled: true);
      addTearDown(rig.dispose);
      await tester.pumpWidget(
        app(rig, child: const Scaffold(body: Text('private'))),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('app-lock')), findsNothing);

      // Home button: inactive -> hidden -> paused, 40 seconds, then back.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      rig.now = rig.now.add(const Duration(seconds: 40));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(
        rig.state.locked ||
            find.byKey(const ValueKey('app-lock')).evaluate().isNotEmpty ||
            rig.authenticator.reasons.length >= 2,
        isTrue,
      );
      expect(
        rig.authenticator.reasons.length,
        2,
        reason: 'prompted again on return',
      );
    });

    testWidgets('a quick return does not lock', (tester) async {
      final rig = Rig(user: 'u1', enabled: true);
      addTearDown(rig.dispose);
      await tester.pumpWidget(
        app(rig, child: const Scaffold(body: Text('private'))),
      );
      await tester.pump();
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      rig.now = rig.now.add(const Duration(seconds: 5));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.byKey(const ValueKey('app-lock')), findsNothing);
      expect(rig.authenticator.reasons.length, 1);
    });

    testWidgets('an unlocked app with the lock off shows no gate', (
      tester,
    ) async {
      final rig = Rig(user: 'u1');
      addTearDown(rig.dispose);
      await tester.pumpWidget(
        app(rig, child: const Scaffold(body: Text('private'))),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('app-lock')), findsNothing);
      expect(rig.authenticator.reasons, isEmpty);
    });
  });
}
