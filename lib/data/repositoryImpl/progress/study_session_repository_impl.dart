import 'package:achievia/data/data_source/progress/study_session_remote_datasource.dart';
import 'package:achievia/domain/repository/progress/study_session_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
@injectable
class StudySessionRepositoryImpl implements StudySessionRepository {
  final StudySessionRemoteDatasource datasource;

  StudySessionRepositoryImpl(this.datasource);

  @override
  Future<void> recordSession({
    required DateTime startedAt,
    required DateTime endedAt,
    String sessionType = 'pomodoro',
  }) => datasource.recordSession(
    startedAt: startedAt,
    endedAt: endedAt,
    sessionType: sessionType,
  );
}
