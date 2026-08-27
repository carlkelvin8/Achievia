import 'package:achievia/data/repositoryImpl/progress/study_session_repository_impl.dart';
import 'package:injectable/injectable.dart';

@injectable
class StudySessionUseCase {
  final StudySessionRepositoryImpl repository;

  StudySessionUseCase(this.repository);

  Future<void> recordSession({
    required DateTime startedAt,
    required DateTime endedAt,
    String sessionType = 'pomodoro',
  }) => repository.recordSession(
    startedAt: startedAt,
    endedAt: endedAt,
    sessionType: sessionType,
  );
}
