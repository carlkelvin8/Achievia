class PomodoroSettingsEntity {
  final Duration focusDuration;
  final Duration shortBreakDuration;
  final Duration longBreakDuration;
  final int sessionsBeforeLongBreak;
  final bool defaultEnabled;
  final bool pomodoroMusicEnabled;
  final bool reviewMusicEnabled;
  final bool breakMusicEnabled;

  const PomodoroSettingsEntity({
    this.focusDuration = const Duration(minutes: 25),
    this.shortBreakDuration = const Duration(minutes: 5),
    this.longBreakDuration = const Duration(minutes: 30),
    this.sessionsBeforeLongBreak = 3,
    this.defaultEnabled = true,
    this.pomodoroMusicEnabled = false,
    this.reviewMusicEnabled = false,
    this.breakMusicEnabled = false,
  });

  PomodoroSettingsEntity copyWith({
    Duration? focusDuration,
    Duration? shortBreakDuration,
    Duration? longBreakDuration,
    int? sessionsBeforeLongBreak,
    bool? defaultEnabled,
    bool? pomodoroMusicEnabled,
    bool? reviewMusicEnabled,
    bool? breakMusicEnabled,
  }) {
    return PomodoroSettingsEntity(
      focusDuration: focusDuration ?? this.focusDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      defaultEnabled: defaultEnabled ?? this.defaultEnabled,
      pomodoroMusicEnabled: pomodoroMusicEnabled ?? this.pomodoroMusicEnabled,
      reviewMusicEnabled: reviewMusicEnabled ?? this.reviewMusicEnabled,
      breakMusicEnabled: breakMusicEnabled ?? this.breakMusicEnabled,
    );
  }
}
