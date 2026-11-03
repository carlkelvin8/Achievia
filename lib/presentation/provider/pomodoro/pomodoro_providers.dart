import 'dart:async';

import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/use_cases/questions/questions_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/domain/entities/widgets/pomodoro_settings_entity.dart';
import 'package:achievia/domain/entities/widgets/pomodoro_state_entity.dart';
import 'package:achievia/domain/use_cases/progress/study_session_use_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

final useCase = Provider<QuestionsUseCase>((ref) => sl<QuestionsUseCase>());
final studySessionUseCaseProvider = Provider<StudySessionUseCase>((ref) {
  return sl<StudySessionUseCase>();
});

class PomodoroSettingsNotifier extends Notifier<PomodoroSettingsEntity> {
  /// Stable SharedPreferences keys holding integer minute/session values.
  /// One key per setting so a stored value is always a plain typed int.
  static const focusMinutesKey = 'pomodoro_focus_minutes';
  static const shortBreakMinutesKey = 'pomodoro_short_break_minutes';
  static const longBreakMinutesKey = 'pomodoro_long_break_minutes';
  static const sessionsBeforeLongKey = 'pomodoro_sessions_before_long';

  bool _hydrated = false;
  bool _disposed = false;
  final Completer<void> _ready = Completer<void>();

  /// Completes once the persisted settings have been applied (or found absent
  /// or unreadable). Screens that start a timer wait for this so they never
  /// begin with the defaults and then jump to the saved values.
  Future<void> get ready => _ready.future;

  @override
  PomodoroSettingsEntity build() {
    ref.onDispose(() => _disposed = true);
    _hydrate();
    return const PomodoroSettingsEntity();
  }

  void setFocusMinutes(int minutes) {
    state = state.copyWith(focusDuration: Duration(minutes: minutes));
    _persist(focusMinutesKey, minutes);
    // If timer is on focus phase and not running, reflect change immediately
    final timer = ref.read(pomodoroProvider);
    if (timer.phase == PomodoroPhase.focus && !timer.isRunning) {
      ref.read(pomodoroProvider.notifier).syncWithSettings();
    }
    _updateDefaultFlag();
  }

  void setShortBreakMinutes(int minutes) {
    state = state.copyWith(shortBreakDuration: Duration(minutes: minutes));
    _persist(shortBreakMinutesKey, minutes);
    final timer = ref.read(pomodoroProvider);
    if (timer.phase == PomodoroPhase.shortBreak && !timer.isRunning) {
      ref.read(pomodoroProvider.notifier).syncWithSettings();
    }
    _updateDefaultFlag();
  }

  void setLongBreakMinutes(int minutes) {
    state = state.copyWith(longBreakDuration: Duration(minutes: minutes));
    _persist(longBreakMinutesKey, minutes);
    final timer = ref.read(pomodoroProvider);
    if (timer.phase == PomodoroPhase.longBreak && !timer.isRunning) {
      ref.read(pomodoroProvider.notifier).syncWithSettings();
    }
    _updateDefaultFlag();
  }

  void setSessionsBeforeLong(int sessions) {
    state = state.copyWith(sessionsBeforeLongBreak: sessions);
    _persist(sessionsBeforeLongKey, sessions);
    _updateDefaultFlag();
  }

  void toggleDefault(bool value) {
    // When turned on, immediately apply default durations
    if (value) {
      state = state.copyWith(
        defaultEnabled: true,
        focusDuration: const Duration(minutes: 25),
        shortBreakDuration: const Duration(minutes: 5),
        longBreakDuration: const Duration(minutes: 30),
        sessionsBeforeLongBreak: 3,
      );
      _persistAll();
      // If timer is paused, sync remaining with current phase
      ref.read(pomodoroProvider.notifier).syncWithSettings();
    } else {
      state = state.copyWith(defaultEnabled: false);
    }
  }

  void _updateDefaultFlag() {
    final isDefault =
        state.focusDuration == const Duration(minutes: 25) &&
        state.shortBreakDuration == const Duration(minutes: 5) &&
        state.longBreakDuration == const Duration(minutes: 30) &&
        state.sessionsBeforeLongBreak == 3;
    if (state.defaultEnabled != isDefault) {
      state = state.copyWith(defaultEnabled: isDefault);
    }
  }

  void togglePomodoroMusic(bool value) {
    state = state.copyWith(pomodoroMusicEnabled: value);
  }

  void toggleReviewMusic(bool value) {
    state = state.copyWith(reviewMusicEnabled: value);
  }

  void toggleBreakMusic(bool value) {
    state = state.copyWith(breakMusicEnabled: value);
  }

  /// Restores the last persisted settings when the provider is created.
  /// Kept additive: missing or invalid keys fall back to their default, and a
  /// failure to read local storage never changes the in-memory default.
  Future<void> _hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed || !_hasStoredSettings(prefs)) return;
      state = PomodoroSettingsEntity(
        focusDuration: Duration(
          minutes: _storedMinutes(prefs, focusMinutesKey, 25),
        ),
        shortBreakDuration: Duration(
          minutes: _storedMinutes(prefs, shortBreakMinutesKey, 5),
        ),
        longBreakDuration: Duration(
          minutes: _storedMinutes(prefs, longBreakMinutesKey, 30),
        ),
        sessionsBeforeLongBreak: _storedSessions(
          prefs,
          sessionsBeforeLongKey,
          3,
        ),
      );
      _updateDefaultFlag();
    } catch (error) {
      debugPrint('Unable to load pomodoro settings: $error');
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  bool _hasStoredSettings(SharedPreferences prefs) =>
      prefs.getInt(focusMinutesKey) != null ||
      prefs.getInt(shortBreakMinutesKey) != null ||
      prefs.getInt(longBreakMinutesKey) != null ||
      prefs.getInt(sessionsBeforeLongKey) != null;

  int _storedMinutes(SharedPreferences prefs, String key, int fallback) {
    final raw = prefs.getInt(key);
    if (raw == null || raw <= 0 || raw > 180) return fallback;
    return raw;
  }

  int _storedSessions(SharedPreferences prefs, String key, int fallback) {
    final raw = prefs.getInt(key);
    if (raw == null || raw < 1 || raw > 10) return fallback;
    return raw;
  }

  void _persistAll() {
    _persist(focusMinutesKey, state.focusDuration.inMinutes);
    _persist(shortBreakMinutesKey, state.shortBreakDuration.inMinutes);
    _persist(longBreakMinutesKey, state.longBreakDuration.inMinutes);
    _persist(sessionsBeforeLongKey, state.sessionsBeforeLongBreak);
  }

  Future<void> _persist(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } catch (error) {
      debugPrint('Unable to persist pomodoro settings: $error');
    }
  }
}

/// Not autoDispose: the timer reads these settings with `ref.read`, so a
/// disposed provider would silently fall back to the 25-minute defaults.
final pomodoroSettingsProvider =
    NotifierProvider<PomodoroSettingsNotifier, PomodoroSettingsEntity>(
      PomodoroSettingsNotifier.new,
    );

class PomodoroNotifier extends Notifier<PomodoroStateEntity> {
  Timer? _timer;
  DateTime? _focusStartedAt;

  @override
  PomodoroStateEntity build() {
    ref.onDispose(() => _timer?.cancel());
    final settings = ref.read(pomodoroSettingsProvider);
    return PomodoroStateEntity(
      phase: PomodoroPhase.focus,
      remaining: settings.focusDuration,
      completedFocusSessions: 0,
      isRunning: false,
    );
  }

  void start() {
    if (state.isRunning) return;
    if (state.phase == PomodoroPhase.focus) {
      _focusStartedAt ??= DateTime.now();
    }
    _timer ??= Timer.periodic(const Duration(seconds: 1), _onTick);
    state = state.copyWith(isRunning: true);
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    _finishFocusSession();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    pause();
    final settings = ref.read(pomodoroSettingsProvider);
    state = PomodoroStateEntity(
      phase: PomodoroPhase.focus,
      remaining: settings.focusDuration,
      completedFocusSessions: 0,
      isRunning: false,
    );
  }

  /// Full length of [phase] with the current settings.
  Duration durationOf(PomodoroPhase phase) {
    final settings = ref.read(pomodoroSettingsProvider);
    switch (phase) {
      case PomodoroPhase.focus:
        return settings.focusDuration;
      case PomodoroPhase.shortBreak:
        return settings.shortBreakDuration;
      case PomodoroPhase.longBreak:
        return settings.longBreakDuration;
    }
  }

  /// Switches to [phase] with a fresh countdown. A running timer keeps
  /// running; a paused one stays paused. Leaving a Focus session records it
  /// like a pause does.
  void selectPhase(PomodoroPhase phase) {
    if (state.phase == phase) return;
    if (state.phase == PomodoroPhase.focus) _finishFocusSession();
    if (phase == PomodoroPhase.focus && state.isRunning) {
      _focusStartedAt = DateTime.now();
    }
    state = state.copyWith(phase: phase, remaining: durationOf(phase));
  }

  void _onTick(Timer t) {
    if (!state.isRunning) return;
    final remaining = state.remaining - const Duration(seconds: 1);
    if (remaining.isNegative || remaining == Duration.zero) {
      _advancePhase();
    } else {
      state = state.copyWith(remaining: remaining);
    }
  }

  void _advancePhase() {
    final settings = ref.read(pomodoroSettingsProvider);
    switch (state.phase) {
      case PomodoroPhase.focus:
        _finishFocusSession();
        final completed = state.completedFocusSessions + 1;
        final isLong = completed % settings.sessionsBeforeLongBreak == 0;
        state = state.copyWith(
          phase: isLong ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak,
          remaining: isLong
              ? settings.longBreakDuration
              : settings.shortBreakDuration,
          completedFocusSessions: completed,
        );
        break;
      case PomodoroPhase.shortBreak:
      case PomodoroPhase.longBreak:
        _focusStartedAt = DateTime.now();
        state = state.copyWith(
          phase: PomodoroPhase.focus,
          remaining: settings.focusDuration,
        );
        break;
    }
  }

  void _finishFocusSession() {
    final startedAt = _focusStartedAt;
    _focusStartedAt = null;
    if (startedAt == null) return;
    final endedAt = DateTime.now();
    if (endedAt.difference(startedAt).inMinutes < 1) return;
    final useCase = ref.read(studySessionUseCaseProvider);
    Future<void>(() async {
      try {
        await useCase.recordSession(
          startedAt: startedAt,
          endedAt: endedAt,
          sessionType: 'pomodoro',
        );
      } catch (error) {
        debugPrint('Unable to record study session: $error');
      }
    });
  }

  // Syncs the remaining time with current settings for the active phase when not running
  void syncWithSettings() {
    if (state.isRunning) return;
    final settings = ref.read(pomodoroSettingsProvider);
    switch (state.phase) {
      case PomodoroPhase.focus:
        state = state.copyWith(remaining: settings.focusDuration);
        break;
      case PomodoroPhase.shortBreak:
        state = state.copyWith(remaining: settings.shortBreakDuration);
        break;
      case PomodoroPhase.longBreak:
        state = state.copyWith(remaining: settings.longBreakDuration);
        break;
    }
  }

  /// Formats a Duration into a readable time string (HH:MM:SS or MM:SS)
  String formatDuration(Duration duration) {
    final mm = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = duration.inHours;
    if (hh > 0) {
      return '${hh.toString().padLeft(2, '0')}:$mm:$ss';
    }
    return '$mm:$ss';
  }

  /// Returns the display label for the current phase
  String getPhaseLabel(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.focus:
        return 'Focus';
      case PomodoroPhase.shortBreak:
        return 'Short Break';
      case PomodoroPhase.longBreak:
        return 'Long Break';
    }
  }
}

/// Per-subject time limit for the Mock Boards exam, in minutes.
///
/// Mock Boards has always used its own fixed limit; it is deliberately
/// independent of the subject Take an Exam configuration and of the
/// user-customizable Pomodoro study settings.
const mockBoardSubjectMinutes = 120;

class MockboardsTimer extends Notifier<PomodoroStateEntity> {
  Timer? _timer;

  @override
  PomodoroStateEntity build() {
    ref.onDispose(() => _timer?.cancel());
    return PomodoroStateEntity(
      phase: PomodoroPhase.focus,
      remaining: const Duration(minutes: mockBoardSubjectMinutes),
      completedFocusSessions: 0,
      isRunning: false,
    );
  }

  void start() {
    if (state.isRunning) return;
    _timer ??= Timer.periodic(const Duration(seconds: 1), _onTick);
    state = state.copyWith(isRunning: true);
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    pause();
    state = PomodoroStateEntity(
      phase: PomodoroPhase.focus,
      remaining: const Duration(minutes: mockBoardSubjectMinutes),
      completedFocusSessions: 0,
      isRunning: false,
    );
  }

  /// Puts back the time left on a subject when an unfinished exam is
  /// continued, so the clock never restarts from the full limit. At least one
  /// second is kept so a clock saved at zero still runs out and advances.
  void restore(Duration remaining) {
    pause();
    const limit = Duration(minutes: mockBoardSubjectMinutes);
    final safe = remaining > limit
        ? limit
        : (remaining < const Duration(seconds: 1)
              ? const Duration(seconds: 1)
              : remaining);
    state = state.copyWith(remaining: safe, isRunning: false);
  }

  void _onTick(Timer t) {
    if (!state.isRunning) return;

    final remaining = state.remaining - const Duration(seconds: 1);

    if (remaining <= Duration.zero) {
      pause(); // stop at 0
      state = state.copyWith(remaining: Duration.zero);
    } else {
      state = state.copyWith(remaining: remaining);
    }
  }

  /// Formats a Duration into a readable time string (HH:MM:SS or MM:SS)
  String formatDuration(Duration duration) {
    final mm = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = duration.inHours;
    if (hh > 0) {
      return '${hh.toString().padLeft(2, '0')}:$mm:$ss';
    }
    return '$mm:$ss';
  }

  /// Returns the display label for the current phase
  String getPhaseLabel(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.focus:
        return 'Focus';
      case PomodoroPhase.shortBreak:
        return 'Short Break';
      case PomodoroPhase.longBreak:
        return 'Long Break';
    }
  }
}

final pomodoroProvider =
    NotifierProvider.autoDispose<PomodoroNotifier, PomodoroStateEntity>(
      () => PomodoroNotifier(),
    );

final timerProvider = NotifierProvider<MockboardsTimer, PomodoroStateEntity>(
  MockboardsTimer.new,
);
