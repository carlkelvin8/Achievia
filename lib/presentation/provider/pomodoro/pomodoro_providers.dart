import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/domain/entities/widgets/pomodoro_settings_entity.dart';
import 'package:achievia/domain/entities/widgets/pomodoro_state_entity.dart';
const Duration fixedTimerDuration = Duration(hours: 120);

class PomodoroSettingsNotifier extends Notifier<PomodoroSettingsEntity> {
  @override
  PomodoroSettingsEntity build() {
    return const PomodoroSettingsEntity();
  }

  void setFocusMinutes(int minutes) {
    state = state.copyWith(focusDuration: Duration(minutes: minutes));
    // If timer is on focus phase and not running, reflect change immediately
    final timer = ref.read(pomodoroProvider);
    if (timer.phase == PomodoroPhase.focus && !timer.isRunning) {
      ref.read(pomodoroProvider.notifier).syncWithSettings();
    }
    _updateDefaultFlag();
  }

  void setShortBreakMinutes(int minutes) {
    state = state.copyWith(shortBreakDuration: Duration(minutes: minutes));
    final timer = ref.read(pomodoroProvider);
    if (timer.phase == PomodoroPhase.shortBreak && !timer.isRunning) {
      ref.read(pomodoroProvider.notifier).syncWithSettings();
    }
    _updateDefaultFlag();
  }

  void setLongBreakMinutes(int minutes) {
    state = state.copyWith(longBreakDuration: Duration(minutes: minutes));
    final timer = ref.read(pomodoroProvider);
    if (timer.phase == PomodoroPhase.longBreak && !timer.isRunning) {
      ref.read(pomodoroProvider.notifier).syncWithSettings();
    }
    _updateDefaultFlag();
  }

  void setSessionsBeforeLong(int sessions) {
    state = state.copyWith(sessionsBeforeLongBreak: sessions);
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
}

final pomodoroSettingsProvider =
    NotifierProvider.autoDispose<PomodoroSettingsNotifier, PomodoroSettingsEntity>(
      () => PomodoroSettingsNotifier(),
    );

class PomodoroNotifier extends Notifier<PomodoroStateEntity> {
  Timer? _timer;

  @override
  PomodoroStateEntity build() {
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
    final settings = ref.read(pomodoroSettingsProvider);
    state = PomodoroStateEntity(
      phase: PomodoroPhase.focus,
      remaining: settings.focusDuration,
      completedFocusSessions: 0,
      isRunning: false,
    );
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
        state = state.copyWith(
          phase: PomodoroPhase.focus,
          remaining: settings.focusDuration,
        );
        break;
    }
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


class MockboardsTimer extends Notifier<PomodoroStateEntity> {
  Timer? _timer;

  @override
  PomodoroStateEntity build() {
    return PomodoroStateEntity(
      phase: PomodoroPhase.focus,
      remaining: fixedTimerDuration,
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
    remaining: fixedTimerDuration,
    completedFocusSessions: 0,
    isRunning: false,
  );
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


final timerProviser = NotifierProvider<MockboardsTimer, PomodoroStateEntity>(MockboardsTimer.new);
