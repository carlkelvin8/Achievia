import 'dart:async';

import 'package:achievia/presentation/provider/auth/account_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Theme state provider
final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// Text size preference (0.0 to 1.0, default 0.5). It only scales study
/// content (questions, answer choices, rationales, notes in Study Deck, Take
/// an Exam and Mock Boards); see ContentTextScale. Stored on the device with
/// SharedPreferences, like the theme, so it survives app restarts.
final textSizeProvider = StateNotifierProvider<TextSizeNotifier, double>(
  (ref) => TextSizeNotifier(),
);

class TextSizeNotifier extends StateNotifier<double> {
  static const String storageKey = 'text_size';
  static const double defaultValue = 0.5;

  TextSizeNotifier() : super(defaultValue) {
    _load();
  }

  bool _editedSinceStart = false;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getDouble(storageKey);
      // A slider move made while the stored value was still loading wins.
      if (stored != null && !_editedSinceStart && mounted) {
        state = _sanitize(stored);
      }
    } catch (error) {
      debugPrint('Unable to load text size: $error');
    }
  }

  /// Updates the size immediately and stores it.
  Future<void> setSize(double value) async {
    _editedSinceStart = true;
    state = _sanitize(value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(storageKey, state);
    } catch (error) {
      debugPrint('Unable to persist text size: $error');
    }
  }

  static double _sanitize(double value) =>
      value.isNaN ? defaultValue : value.clamp(0.0, 1.0);
}

/// Current authenticated account id used to scope the stored sleep time.
///
/// Guarded so an uninitialized Supabase (or a signed-out state) yields `null`
/// instead of throwing; settings keep their default and nothing is written.
/// Follows sign-in, sign-out and account switches so dependants rebuild.
final sleepTimeUserProvider = Provider<String?>((ref) {
  try {
    final account = ref.watch(activeAccountIdProvider);
    if (account.hasValue) return account.value;
    return Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {
    return null;
  }
});

/// Persisted, account-scoped sleep time.
///
/// The same account keeps one value stored on the device; switching accounts
/// loads that other account's value and never touches their stored data.
class SleepTimeNotifier extends Notifier<TimeOfDay> {
  static const defaultSleepTime = TimeOfDay(hour: 20, minute: 0);

  static String _hourKey(String userId) => 'sleep_time_${userId}_hour';
  static String _minuteKey(String userId) => 'sleep_time_${userId}_minute';

  bool _disposed = false;
  String? _hydratedFor;

  /// True once the user saved a value since the last build; a slow read of the
  /// stored value must never overwrite it.
  bool _editedSinceBuild = false;
  Completer<void> _ready = Completer<void>();

  /// Completes once the stored value for the current account has been applied
  /// (or found absent/invalid). Replaced whenever the account changes.
  Future<void> get ready => _ready.future;
  bool get isHydrated => _ready.isCompleted;

  @override
  TimeOfDay build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    final userId = ref.watch(sleepTimeUserProvider);
    _hydratedFor = null;
    _editedSinceBuild = false;
    _ready = Completer<void>();
    _hydrate(userId, _ready);
    return defaultSleepTime;
  }

  Future<void> _hydrate(String? userId, Completer<void> done) async {
    if (userId == null) {
      done.complete();
      return;
    }
    _hydratedFor = userId;
    TimeOfDay? stored;
    try {
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt(_hourKey(userId));
      final minute = prefs.getInt(_minuteKey(userId));
      if (hour != null &&
          minute != null &&
          _isValidHour(hour) &&
          _isValidMinute(minute)) {
        stored = TimeOfDay(hour: hour, minute: minute);
      }
    } catch (error) {
      debugPrint('Unable to load sleep time: $error');
    }
    final stale = _disposed || _hydratedFor != userId;
    // Hydration is marked complete BEFORE the stored value is announced, so a
    // listener reacting to the new value already sees isHydrated == true. The
    // other order made the scheduler ignore the stored time at startup.
    if (!done.isCompleted) done.complete();
    if (stale || _editedSinceBuild || stored == null) return;
    state = stored;
  }

  /// Stores a new sleep time for the current account. State updates
  /// immediately; a local write failure never throws to the UI.
  Future<void> save(TimeOfDay time) async {
    _editedSinceBuild = true;
    state = TimeOfDay(hour: time.hour % 24, minute: time.minute % 60);
    final userId = ref.read(sleepTimeUserProvider);
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_hourKey(userId), state.hour);
      await prefs.setInt(_minuteKey(userId), state.minute);
    } catch (error) {
      debugPrint('Unable to persist sleep time: $error');
    }
  }

  static bool _isValidHour(int value) => value >= 0 && value <= 23;
  static bool _isValidMinute(int value) => value >= 0 && value <= 59;
}

// Sleep time provider
final sleepTimeProvider = NotifierProvider<SleepTimeNotifier, TimeOfDay>(
  SleepTimeNotifier.new,
);
