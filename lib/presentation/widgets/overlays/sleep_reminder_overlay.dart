import 'dart:async';

import 'package:achievia/core/utils/alert_sound.dart';
import 'package:achievia/presentation/widgets/overlays/welcome_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The sound played when a reminder appears (overridden in tests).
final alertSoundProvider = Provider<AlertSound>((ref) => PlatformAlertSound());

/// How long a Sleep Time Reminder stays on screen.
const Duration kSleepReminderDuration = Duration(seconds: 30);

/// Shows the Sleep Time Reminder as a centered card over a dimmed, input
/// blocking backdrop, plays one alert sound, and removes it after
/// [visibleFor] measured from when it appeared.
///
/// At most one reminder exists at a time ([showIn] ignores a second request
/// while one is visible, so one occurrence never plays two sounds or two
/// countdowns). The countdown is a wall-clock deadline, not a tick counter:
/// when the app comes back from the background the elapsed time is checked,
/// so a paused timer never restarts the 30 seconds and a stale card never
/// survives. Only the entry created here is ever removed.
class SleepReminderOverlayController {
  SleepReminderOverlayController({
    ToastSlot? slot,
    this.priority = 1,
    AlertSound? sound,
    DateTime Function()? clock,
    this.visibleFor = kSleepReminderDuration,
  }) : _slot = slot,
       _sound = sound ?? PlatformAlertSound(),
       _clock = clock ?? DateTime.now;

  final ToastSlot? _slot;
  final int priority;
  final AlertSound _sound;
  final DateTime Function() _clock;
  final Duration visibleFor;

  OverlayEntry? _entry;
  Timer? _timer;
  DateTime? _shownAt;
  AppLifecycleListener? _lifecycle;

  bool get isShowing => _entry != null;

  /// Inserts the reminder into [overlay]. Returns false (and does nothing,
  /// not even a sound) when one is already visible, there is no overlay, or a
  /// toast of equal or higher priority owns the shared slot.
  bool showIn(OverlayState? overlay, String message) {
    if (_entry != null || overlay == null) return false;
    if (_slot?.claim(priority, dismissNow) == false) return false;

    final entry = OverlayEntry(
      builder: (_) => SleepReminderCard(message: message),
    );
    _entry = entry;
    _shownAt = _clock();
    overlay.insert(entry);

    // Elapsed time decides, the timer only wakes us up.
    _timer = Timer(visibleFor, _expire);
    _lifecycle = AppLifecycleListener(onResume: _expire);

    // Once per occurrence: this is the only place the sound is started.
    unawaited(_sound.play().catchError((Object _) {}));
    return true;
  }

  /// The timer fired or the app resumed: remove the card if its time is up,
  /// otherwise wait only for what is left.
  void _expire() {
    final shownAt = _shownAt;
    if (_entry == null || shownAt == null) return;
    final elapsed = _clock().difference(shownAt);
    if (elapsed >= visibleFor) {
      _remove();
      return;
    }
    // A clock that moved backwards must not extend the card indefinitely.
    final remaining =
        visibleFor - (elapsed.isNegative ? Duration.zero : elapsed);
    _timer?.cancel();
    _timer = Timer(remaining, _expire);
  }

  void _remove() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    _shownAt = null;
    _timer?.cancel();
    _timer = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    _slot?.release(dismissNow);
    entry.remove();
    entry.dispose();
  }

  /// Removes the reminder immediately (account change, host disposal).
  void dismissNow() => _remove();

  void dispose() => _remove();
}

/// The card itself: backdrop, back-button guard and centered message.
class SleepReminderCard extends StatelessWidget {
  const SleepReminderCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;

    Widget content = Stack(
      key: const ValueKey('sleep-reminder'),
      fit: StackFit.expand,
      children: [
        // Semi-transparent gray backdrop. Absorbs every pointer event, so the
        // screen below cannot be touched and a tap outside does nothing.
        const AbsorbPointer(
          child: ColoredBox(
            key: ValueKey('sleep-reminder-backdrop'),
            color: Color(0x99424242),
          ),
        ),
        // Exact center of the screen (not of the safe area), on every size.
        Center(
          child: AbsorbPointer(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (width - 48).clamp(200.0, 360.0),
              ),
              child: Material(
                key: const ValueKey('sleep-reminder-card'),
                color: theme.colorScheme.surface,
                elevation: 8,
                shadowColor: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bedtime_outlined,
                        size: 36,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    // The Android back button would otherwise pop the screen below. The
    // listener takes the press and ignores it for the 30 seconds. (No Router,
    // as in simple widget tests, means there is nothing to intercept.)
    if (Router.maybeOf(context) != null) {
      content = BackButtonListener(
        onBackButtonPressed: () async => true,
        child: content,
      );
    }
    return content;
  }
}
