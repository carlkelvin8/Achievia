import 'dart:async';

import 'package:achievia/core/utils/welcome_session_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef TimerFactory = Timer Function(Duration delay, void Function() run);

/// Debug-builds-only trace of the Sleep Time Reminder. Never logs ids, names,
/// tokens or profile data, only times and decisions.
void sleepReminderLog(String message) {
  if (kDebugMode) debugPrint('[SleepReminder] $message');
}

String _hhmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Pure date helpers for the Sleep Time Reminder. Sleep Time is a wall-clock
/// time on the device, so everything here uses the device's local time.
class SleepReminderSchedule {
  const SleepReminderSchedule._();

  static bool isValid(TimeOfDay time) =>
      time.hour >= 0 &&
      time.hour <= 23 &&
      time.minute >= 0 &&
      time.minute <= 59;

  /// Canonical day key (yyyy-MM-dd, local) used for last-fired tracking.
  static String dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Identity of one reminder occurrence: the calendar day AND the configured
  /// time (yyyy-MM-dd HH:mm). Duplicate protection is per occurrence, so a time
  /// the user sets later the same day still fires, while the same occurrence
  /// can never fire twice.
  static String occurrenceKey(DateTime day, TimeOfDay time) =>
      '${dayKey(day)} '
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  /// The configured time on the calendar day of [now].
  static DateTime occurrenceOn(DateTime now, TimeOfDay time) =>
      DateTime(now.year, now.month, now.day, time.hour, time.minute);

  /// The next real calendar occurrence strictly after [now]: today if the time
  /// is still ahead, otherwise tomorrow. Independent of when it was saved.
  static DateTime nextOccurrence(DateTime now, TimeOfDay time) {
    final today = occurrenceOn(now, time);
    if (today.isAfter(now)) return today;
    return DateTime(now.year, now.month, now.day + 1, time.hour, time.minute);
  }

  /// "Hello, Ana! It's already 8:00 PM. Time to take a rest!" — the name is
  /// omitted when it is missing or a placeholder value.
  static String message({required String? firstName, required String time}) {
    final name = WelcomeSessionService.usableName(firstName);
    final greeting = name != null ? 'Hello, $name!' : 'Hello!';
    return "$greeting It's already $time. Time to take a rest!";
  }
}

/// Owns the foreground schedule of the Sleep Time Reminder: current user,
/// configured time, one timer aimed at the next absolute occurrence, and the
/// per-user last-fired day. It never polls; each timer targets one instant.
///
/// A reminder can only be shown while the app is running in the foreground.
class SleepReminderScheduler {
  SleepReminderScheduler({
    required this.clock,
    required this.onFire,
    Future<SharedPreferences> Function()? prefs,
    TimerFactory? timerFactory,
    this.grace = const Duration(minutes: 10),
  }) : _prefs = prefs ?? SharedPreferences.getInstance,
       _timerFactory = timerFactory ?? Timer.new;

  /// How long after the configured time a missed reminder (app resumed, timer
  /// delayed) may still be delivered once. Later than this it is skipped.
  final Duration grace;
  final DateTime Function() clock;
  final void Function(TimeOfDay time) onFire;
  final Future<SharedPreferences> Function() _prefs;
  final TimerFactory _timerFactory;

  static String lastFiredKey(String userId) =>
      'sleep_reminder_last_fired_$userId';

  Timer? _timer;
  String? _userId;
  TimeOfDay? _time;
  String? _lastFired;
  int _generation = 0;
  bool _disposed = false;

  bool get isScheduled => _timer?.isActive ?? false;
  String? get userId => _userId;
  TimeOfDay? get time => _time;

  /// (Re)configures the schedule. A null [userId] or [time] cancels it.
  /// Calling again with unchanged input is a no-op unless [catchUp] is set.
  /// [catchUp] allows delivering today's reminder if it was missed within
  /// [grace]; it is set on start/resume, never when the user edits the time.
  Future<void> configure({
    required String? userId,
    required TimeOfDay? time,
    bool catchUp = false,
  }) async {
    if (_disposed) return;
    final valid =
        userId != null && time != null && SleepReminderSchedule.isValid(time);
    if (valid &&
        userId == _userId &&
        time == _time &&
        isScheduled &&
        !catchUp) {
      return;
    }
    final generation = ++_generation;
    sleepReminderLog(
      'configure valid=$valid time=${time == null ? '-' : _hhmm(time)} '
      'catchUp=$catchUp',
    );
    if (!valid) {
      _cancel();
      _userId = null;
      _time = null;
      _lastFired = null;
      return;
    }
    if (userId != _userId) {
      _cancel();
      _userId = userId;
      _time = null;
      _lastFired = await _readLastFired(userId);
      if (_disposed || generation != _generation) return;
    }
    _time = time;
    _arm(catchUp: catchUp);
  }

  /// Recomputes the schedule after the app returns to the foreground.
  void resume() {
    if (_disposed || _userId == null || _time == null) return;
    _arm(catchUp: true);
  }

  void _arm({required bool catchUp}) {
    _timer?.cancel();
    final time = _time;
    if (_disposed || time == null) return;
    final now = clock();
    final occurrence = SleepReminderSchedule.occurrenceKey(now, time);
    final todaysTime = SleepReminderSchedule.occurrenceOn(now, time);

    var firedToday = _lastFired == occurrence;
    if (!firedToday &&
        catchUp &&
        !now.isBefore(todaysTime) &&
        now.difference(todaysTime) <= grace) {
      _fire(occurrence, time);
      firedToday = true;
    }

    final next = firedToday
        ? DateTime(now.year, now.month, now.day + 1, time.hour, time.minute)
        : SleepReminderSchedule.nextOccurrence(now, time);
    final generation = _generation;
    final delay = next.difference(now);
    sleepReminderLog(
      'armed for ${_hhmm(time)}: now=${now.toIso8601String()} '
      'next=${next.toIso8601String()} in ${delay.inSeconds}s '
      '(firedToday=$firedToday)',
    );
    _timer = _timerFactory(delay, () {
      if (_disposed || generation != _generation) return;
      sleepReminderLog('timer woke at ${clock().toIso8601String()}');
      _arm(catchUp: true);
    });
  }

  void _fire(String occurrence, TimeOfDay time) {
    sleepReminderLog('FIRE $occurrence');
    _lastFired = occurrence;
    final userId = _userId;
    if (userId != null) unawaited(_writeLastFired(userId, occurrence));
    try {
      onFire(time);
    } catch (error) {
      debugPrint('Sleep reminder could not be shown: ${error.runtimeType}');
    }
  }

  Future<String?> _readLastFired(String userId) async {
    try {
      return (await _prefs()).getString(lastFiredKey(userId));
    } catch (error) {
      debugPrint('Sleep reminder state unavailable: ${error.runtimeType}');
      return null;
    }
  }

  Future<void> _writeLastFired(String userId, String occurrence) async {
    try {
      await (await _prefs()).setString(lastFiredKey(userId), occurrence);
    } catch (error) {
      debugPrint('Sleep reminder state not saved: ${error.runtimeType}');
    }
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _cancel();
  }
}
