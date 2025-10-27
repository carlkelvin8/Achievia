import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

// Theme state provider
final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// Text size provider (0.0 to 1.0 scale)
final textSizeProvider = StateProvider<double>((ref) => 0.5);

// Sleep time provider
final sleepTimeProvider = StateProvider<TimeOfDay>(
  (ref) => const TimeOfDay(hour: 20, minute: 0),
);

// Pomodoro settings provider
final pomodoroSettingsProvider = StateProvider<PomodoroSettings>(
  (ref) => PomodoroSettings(),
);

// Examination settings provider
final examinationSettingsProvider = StateProvider<ExaminationSettings>(
  (ref) => ExaminationSettings(),
);

class PomodoroSettings {
  final int workDuration; // in minutes
  final int shortBreak; // in minutes
  final int longBreak; // in minutes
  final int sessionsUntilLongBreak;

  PomodoroSettings({
    this.workDuration = 25,
    this.shortBreak = 5,
    this.longBreak = 15,
    this.sessionsUntilLongBreak = 4,
  });

  PomodoroSettings copyWith({
    int? workDuration,
    int? shortBreak,
    int? longBreak,
    int? sessionsUntilLongBreak,
  }) {
    return PomodoroSettings(
      workDuration: workDuration ?? this.workDuration,
      shortBreak: shortBreak ?? this.shortBreak,
      longBreak: longBreak ?? this.longBreak,
      sessionsUntilLongBreak:
          sessionsUntilLongBreak ?? this.sessionsUntilLongBreak,
    );
  }
}

class ExaminationSettings {
  final int examDuration; // in minutes
  final int questionTimeLimit; // in seconds
  final bool autoSubmit;
  final bool showTimer;

  ExaminationSettings({
    this.examDuration = 120,
    this.questionTimeLimit = 60,
    this.autoSubmit = true,
    this.showTimer = true,
  });

  ExaminationSettings copyWith({
    int? examDuration,
    int? questionTimeLimit,
    bool? autoSubmit,
    bool? showTimer,
  }) {
    return ExaminationSettings(
      examDuration: examDuration ?? this.examDuration,
      questionTimeLimit: questionTimeLimit ?? this.questionTimeLimit,
      autoSubmit: autoSubmit ?? this.autoSubmit,
      showTimer: showTimer ?? this.showTimer,
    );
  }
}
