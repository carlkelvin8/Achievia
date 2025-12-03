enum PomodoroPhase { focus, shortBreak, longBreak }

class PomodoroStateEntity {
  final PomodoroPhase phase;
  final Duration remaining;
  final int completedFocusSessions;
  final bool isRunning;

  const PomodoroStateEntity({
    required this.phase,
    required this.remaining,
    this.completedFocusSessions = 0,
    this.isRunning = false,
  });

  PomodoroStateEntity copyWith({
    PomodoroPhase? phase,
    Duration? remaining,
    int? completedFocusSessions,
    bool? isRunning,
  }) {
    return PomodoroStateEntity(
      phase: phase ?? this.phase,
      remaining: remaining ?? this.remaining,
      completedFocusSessions:
          completedFocusSessions ?? this.completedFocusSessions,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}
