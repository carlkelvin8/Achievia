import 'package:achievia/domain/entities/api/progress/progress_day_entity.dart';

abstract class ProgressRepository {
  Future<void> markTodayActive();
  Future<List<ProgressDayEntity>> getActiveDays();
}
