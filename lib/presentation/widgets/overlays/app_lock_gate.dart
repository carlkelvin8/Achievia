import 'package:achievia/presentation/provider/auth/app_lock_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Covers the whole app with a lock screen while the biometric lock is
/// active. It sits above the router, so no screen, dialog or deep link is
/// reachable until the check passes.
class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _promptedForThisLock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    final controller = ref.read(appLockProvider.notifier);
    switch (lifecycle) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        controller.onBackgrounded();
      case AppLifecycleState.resumed:
        controller.onResumed();
        // A fresh resume under lock asks again.
        _promptedForThisLock = false;
        _maybePrompt();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _maybePrompt() {
    if (!mounted || _promptedForThisLock) return;
    final state = ref.read(appLockProvider);
    if (!state.locked || state.busy) return;
    _promptedForThisLock = true;
    ref.read(appLockProvider.notifier).unlock();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appLockProvider);

    if (state.locked) {
      // Ask for the fingerprint as soon as the lock screen is on screen.
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
    } else {
      _promptedForThisLock = false;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Kept mounted so the user returns to exactly where they were, but
        // hidden from touch and from accessibility while locked.
        ExcludeSemantics(
          excluding: state.locked,
          child: IgnorePointer(ignoring: state.locked, child: widget.child),
        ),
        if (state.locked) _LockScreen(state: state),
      ],
    );
  }
}

class _LockScreen extends ConsumerWidget {
  final AppLockState state;
  const _LockScreen({required this.state});

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // The router sends a signed-out user to the login screen.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final message = appLockIssueMessage(state.issue);
    return Material(
      key: const ValueKey('app-lock'),
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Achievia is locked',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use your fingerprint or face to continue.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    key: const ValueKey('app-lock-message'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const ValueKey('app-lock-unlock'),
                  onPressed: state.busy
                      ? null
                      : () => ref.read(appLockProvider.notifier).unlock(),
                  icon: const Icon(Icons.fingerprint),
                  label: Text(state.busy ? 'Checking...' : 'Unlock'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  key: const ValueKey('app-lock-logout'),
                  onPressed: state.busy ? null : _signOut,
                  child: const Text('Log out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
