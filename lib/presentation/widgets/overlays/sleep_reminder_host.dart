import 'package:achievia/core/utils/sleep_reminder_scheduler.dart';
import 'package:achievia/core/utils/welcome_session_service.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:achievia/presentation/provider/settings/settings_provider.dart';
import 'package:achievia/presentation/provider/task/local_day_provider.dart';
import 'package:achievia/presentation/widgets/overlays/sleep_reminder_overlay.dart';
import 'package:achievia/presentation/widgets/overlays/welcome_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Application-level host of the Sleep Time Reminder.
///
/// Sits above the router (via `MaterialApp.router(builder:)`), so scheduling
/// belongs to the signed-in session rather than to any screen. When the
/// configured time arrives the reminder card is inserted into the root
/// navigator's overlay, above the current route and any dialog, without
/// navigating or touching route state. Only works while the app is in the
/// foreground; there is no OS notification when it is backgrounded or closed.
class SleepReminderHost extends ConsumerStatefulWidget {
  const SleepReminderHost({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  ConsumerState<SleepReminderHost> createState() => _SleepReminderHostState();
}

class _SleepReminderHostState extends ConsumerState<SleepReminderHost> {
  late final SleepReminderOverlayController _toast;
  late final SleepReminderScheduler _scheduler;
  late final AppLifecycleListener _lifecycle;
  int _syncGeneration = 0;

  @override
  void initState() {
    super.initState();
    // Priority 1 outranks the welcome message (0): the reminder replaces it.
    _toast = SleepReminderOverlayController(
      slot: ref.read(toastSlotProvider),
      priority: 1,
      sound: ref.read(alertSoundProvider),
      clock: () => ref.read(taskClockProvider)(),
    );
    _scheduler = SleepReminderScheduler(
      clock: () => ref.read(taskClockProvider)(),
      onFire: _show,
    );
    _lifecycle = AppLifecycleListener(onResume: _scheduler.resume);
    ref.listenManual<String?>(
      sleepTimeUserProvider,
      (_, next) => _onUser(next),
      fireImmediately: true,
    );
    ref.listenManual<TimeOfDay>(sleepTimeProvider, (_, next) => _onTime(next));
  }

  /// Account resolved, changed or signed out. Hides any card of the previous
  /// account and waits for the new account's stored time before scheduling.
  Future<void> _onUser(String? userId) async {
    final generation = ++_syncGeneration;
    sleepReminderLog('account changed: signedIn=${userId != null}');
    _toast.dismissNow();
    if (userId == null) {
      await _scheduler.configure(userId: null, time: null);
      return;
    }
    if (!await _untilHydrated() || generation != _syncGeneration) {
      sleepReminderLog('account sync superseded');
      return;
    }
    await _scheduler.configure(
      userId: userId,
      time: ref.read(sleepTimeProvider),
      catchUp: true,
    );
  }

  /// Waits until the Sleep Time of the CURRENT account has been read from
  /// storage. The provider rebuilds whenever the account resolves or changes,
  /// and Riverpod applies that rebuild lazily on the next read. So the state
  /// is read first on every pass: otherwise the check below would look at the
  /// previous, already finished instance and hand back the default time.
  /// False if the host was disposed meanwhile.
  Future<bool> _untilHydrated() async {
    while (mounted) {
      ref.read(sleepTimeProvider);
      final notifier = ref.read(sleepTimeProvider.notifier);
      if (notifier.isHydrated) return true;
      await notifier.ready;
    }
    return false;
  }

  /// The user edited (or hydration applied) the Sleep Time. A change that
  /// arrives before the stored value was read is never dropped: the scheduler
  /// is synced to the latest value as soon as hydration finishes.
  Future<void> _onTime(TimeOfDay time) async {
    sleepReminderLog('time changed to ${time.hour}:${time.minute}');
    final generation = _syncGeneration;
    if (!await _untilHydrated() || generation != _syncGeneration) return;
    await _scheduler.configure(
      userId: ref.read(sleepTimeUserProvider),
      time: ref.read(sleepTimeProvider),
    );
  }

  void _show(TimeOfDay time) {
    if (!mounted) return;
    final context = widget.navigatorKey.currentContext;
    final overlay = widget.navigatorKey.currentState?.overlay;
    sleepReminderLog(
      'show requested: context=${context != null} overlay=${overlay != null}',
    );
    if (context == null || overlay == null) return;
    _toast.showIn(
      overlay,
      SleepReminderSchedule.message(
        firstName: _firstName(),
        time: time.format(context),
      ),
    );
  }

  /// Already-loaded profile first, then auth metadata. Never triggers a
  /// profile query of its own.
  String? _firstName() {
    final loaded = ref.exists(profileProvider)
        ? ref.read(profileProvider).value?.firstName
        : null;
    final fromProfile = WelcomeSessionService.usableName(loaded);
    if (fromProfile != null) return fromProfile;
    try {
      final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
      return WelcomeSessionService.usableName(meta?['first_name']?.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _syncGeneration++;
    _lifecycle.dispose();
    _scheduler.dispose();
    _toast.dismissNow();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
