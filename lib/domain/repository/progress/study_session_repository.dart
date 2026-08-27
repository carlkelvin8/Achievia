abstract class StudySessionRepository {
  Future<void> recordSession({
    required DateTime startedAt,
    required DateTime endedAt,
    String sessionType = 'pomodoro',
  });
}
