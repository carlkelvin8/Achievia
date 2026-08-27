import 'package:achievia/domain/entities/api/progress/progress_day_entity.dart';
import 'package:achievia/data/models/progress/progress_snapshot_dto.dart';

abstract class ProgressRepository {
  Future<void> markTodayActive();
  Future<List<ProgressDayEntity>> getActiveDays();
  Future<ProgressSnapshotDto> getSnapshot();
}
