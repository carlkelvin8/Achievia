import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/domain/entities/pomodoro_settings_entity.dart';
import 'package:achievia/domain/entities/pomodoro_state_entity.dart';

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
  }

  void setShortBreakMinutes(int minutes) {
    state = state.copyWith(shortBreakDuration: Duration(minutes: minutes));
    final timer = ref.read(pomodoroProvider);
    if (timer.phase == PomodoroPhase.shortBreak && !timer.isRunning) {
      ref.read(pomodoroProvider.notifier).syncWithSettings();
    }
  }

  void setLongBreakMinutes(int minutes) {
    state = state.copyWith(longBreakDuration: Duration(minutes: minutes));
    final timer = ref.read(pomodoroProvider);
    if (timer.phase == PomodoroPhase.longBreak && !timer.isRunning) {
      ref.read(pomodoroProvider.notifier).syncWithSettings();
    }
  }

  void setSessionsBeforeLong(int sessions) {
    state = state.copyWith(sessionsBeforeLongBreak: sessions);
  }

  void toggleDefault(bool value) {
    state = state.copyWith(defaultEnabled: value);
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
    NotifierProvider<PomodoroSettingsNotifier, PomodoroSettingsEntity>(
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
}

final pomodoroProvider =
    NotifierProvider<PomodoroNotifier, PomodoroStateEntity>(
      () => PomodoroNotifier(),
    );
