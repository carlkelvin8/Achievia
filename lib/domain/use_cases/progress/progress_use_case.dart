import 'package:achievia/data/repositoryImpl/progress/progress_repository_impl.dart';
import 'package:achievia/domain/entities/api/progress/progress_day_entity.dart';
import 'package:achievia/data/models/progress/progress_snapshot_dto.dart';
import 'package:injectable/injectable.dart';

@injectable
class ProgressUseCase {
  final ProgressRepositoryImpl repository;

  ProgressUseCase(this.repository);

  Future<void> markTodayActive() => repository.markTodayActive();

  Future<List<ProgressDayEntity>> getActiveDays() => repository.getActiveDays();
  Future<ProgressSnapshotDto> getSnapshot() => repository.getSnapshot();
}
