import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/di/local_storage_service.dart';
import 'package:achievia/data/data_source/auth/biometric_authenticator.dart';
import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Where the on/off choice is kept (per account, on this device).
abstract class AppLockStore {
  bool isEnabled(String userId);
  Future<void> setEnabled(String userId, bool enabled);
}

class LocalAppLockStore implements AppLockStore {
  LocalStorageService get _storage => sl<LocalStorageService>();

  @override
  bool isEnabled(String userId) => _storage.isAppLockEnabled(userId);

  @override
  Future<void> setEnabled(String userId, bool enabled) =>
      _storage.setAppLockEnabled(userId, enabled);
}

final appLockStoreProvider = Provider<AppLockStore>(
  (ref) => LocalAppLockStore(),
);

final biometricAuthenticatorProvider = Provider<BiometricAuthenticator>(
  (ref) => LocalAuthBiometricAuthenticator(),
);

final appLockClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// How long the app may stay in the background before it locks again. Short
/// enough to protect a phone left unattended, long enough that glancing at an
/// authenticator app or another app does not prompt every time.
final appLockGraceProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 30),
);

/// The signed-in user id, readable synchronously so the very first frame after
/// a cold start is already locked (no flash of private content).
final appLockUserIdProvider = Provider<String?>((ref) {
  final streamed = ref.watch(activeAccountIdProvider);
  if (streamed.hasValue) return streamed.value;
  try {
    return Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {
    // Supabase is not initialised (tests, very early start): no account.
    return null;
  }
});

class _ColdStartFlag {
  bool pending = true;
}

/// True only until the first state was built after the process started: a
/// login later in the same run is not locked behind a second prompt.
final _coldStartProvider = Provider<_ColdStartFlag>((ref) => _ColdStartFlag());

enum AppLockIssue { none, failed, lockedOut, unavailable, error }

class AppLockState {
  final bool enabled;
  final bool locked;
  final bool busy;
  final AppLockIssue issue;

  const AppLockState({
    this.enabled = false,
    this.locked = false,
    this.busy = false,
    this.issue = AppLockIssue.none,
  });

  AppLockState copyWith({
    bool? enabled,
    bool? locked,
    bool? busy,
    AppLockIssue? issue,
  }) => AppLockState(
    enabled: enabled ?? this.enabled,
    locked: locked ?? this.locked,
    busy: busy ?? this.busy,
    issue: issue ?? this.issue,
  );
}

enum AppLockToggleResult {
  enabled,
  disabled,
  notAvailable,
  notEnrolled,
  canceled,
  failed,
}

class AppLockController extends Notifier<AppLockState> {
  DateTime? _backgroundedAt;

  @override
  AppLockState build() {
    final userId = ref.watch(appLockUserIdProvider);
    final flag = ref.read(_coldStartProvider);
    final coldStart = flag.pending;
    flag.pending = false;
    if (userId == null) return const AppLockState();
    final enabled = ref.read(appLockStoreProvider).isEnabled(userId);
    return AppLockState(enabled: enabled, locked: enabled && coldStart);
  }

  /// The app left the foreground (paused / hidden, not a system dialog).
  void onBackgrounded() {
    if (state.busy) return;
    // Only the first event counts. Coming back passes through `hidden` again
    // (paused -> hidden -> inactive -> resumed); recording that one would reset
    // the clock and the lock would never trigger.
    _backgroundedAt ??= ref.read(appLockClockProvider)();
  }

  /// The app came back: lock again if it was away for at least the grace time.
  void onResumed() {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (since == null || state.busy || !state.enabled || state.locked) return;
    final away = ref.read(appLockClockProvider)().difference(since);
    if (away >= ref.read(appLockGraceProvider)) {
      state = state.copyWith(locked: true, issue: AppLockIssue.none);
    }
  }

  /// Asks for the fingerprint / face to open the app.
  Future<bool> unlock() async {
    if (!state.locked || state.busy) return false;
    state = state.copyWith(busy: true, issue: AppLockIssue.none);
    final outcome = await ref
        .read(biometricAuthenticatorProvider)
        .authenticate('Unlock Achievia');
    if (outcome == BiometricOutcome.success) {
      state = state.copyWith(locked: false, busy: false);
      return true;
    }
    state = state.copyWith(busy: false, issue: _issueFor(outcome));
    return false;
  }

  /// Turns the lock on. The user must pass the check first, which proves the
  /// biometrics really work on this device before the app depends on them.
  Future<AppLockToggleResult> enable() async {
    final userId = ref.read(appLockUserIdProvider);
    if (userId == null || state.busy) return AppLockToggleResult.failed;
    final authenticator = ref.read(biometricAuthenticatorProvider);
    switch (await authenticator.availability()) {
      case BiometricAvailability.unsupported:
        return AppLockToggleResult.notAvailable;
      case BiometricAvailability.notEnrolled:
        return AppLockToggleResult.notEnrolled;
      case BiometricAvailability.available:
        break;
    }
    state = state.copyWith(busy: true);
    final outcome = await authenticator.authenticate(
      'Confirm to turn on biometric lock',
    );
    if (outcome != BiometricOutcome.success) {
      state = state.copyWith(busy: false);
      return outcome == BiometricOutcome.canceled
          ? AppLockToggleResult.canceled
          : AppLockToggleResult.failed;
    }
    await ref.read(appLockStoreProvider).setEnabled(userId, true);
    state = state.copyWith(enabled: true, locked: false, busy: false);
    return AppLockToggleResult.enabled;
  }

  /// Turning it off also needs a successful check, so a borrowed unlocked
  /// phone cannot quietly remove the protection.
  Future<AppLockToggleResult> disable() async {
    final userId = ref.read(appLockUserIdProvider);
    if (userId == null || state.busy) return AppLockToggleResult.failed;
    state = state.copyWith(busy: true);
    final outcome = await ref
        .read(biometricAuthenticatorProvider)
        .authenticate('Confirm to turn off biometric lock');
    if (outcome != BiometricOutcome.success) {
      state = state.copyWith(busy: false);
      return outcome == BiometricOutcome.canceled
          ? AppLockToggleResult.canceled
          : AppLockToggleResult.failed;
    }
    await ref.read(appLockStoreProvider).setEnabled(userId, false);
    state = state.copyWith(enabled: false, locked: false, busy: false);
    return AppLockToggleResult.disabled;
  }

  AppLockIssue _issueFor(BiometricOutcome outcome) {
    switch (outcome) {
      case BiometricOutcome.failed:
        return AppLockIssue.failed;
      case BiometricOutcome.lockedOut:
        return AppLockIssue.lockedOut;
      case BiometricOutcome.unavailable:
        return AppLockIssue.unavailable;
      case BiometricOutcome.canceled:
        return AppLockIssue.none;
      case BiometricOutcome.error:
      case BiometricOutcome.success:
        return AppLockIssue.error;
    }
  }
}

final appLockProvider = NotifierProvider<AppLockController, AppLockState>(
  AppLockController.new,
);

String appLockIssueMessage(AppLockIssue issue) {
  switch (issue) {
    case AppLockIssue.none:
      return '';
    case AppLockIssue.failed:
      return 'That did not match. Try again.';
    case AppLockIssue.lockedOut:
      return 'Too many attempts. Wait a moment, then try again.';
    case AppLockIssue.unavailable:
      return 'Biometrics are not available on this device right now. '
          'Log out and sign in with your password.';
    case AppLockIssue.error:
      return 'We could not check your fingerprint. Try again.';
  }
}
