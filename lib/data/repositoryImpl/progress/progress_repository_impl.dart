import 'package:achievia/data/data_source/progress/progress_remote_datasource.dart';
import 'package:achievia/domain/entities/api/progress/progress_day_entity.dart';
import 'package:achievia/domain/repository/progress/progress_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
@injectable
class ProgressRepositoryImpl implements ProgressRepository {
  final ProgressRemoteDatasource datasource;

  ProgressRepositoryImpl(this.datasource);

  @override
  Future<void> markTodayActive() => datasource.markTodayActive();

  @override
  Future<List<ProgressDayEntity>> getActiveDays() async {
    final dtos = await datasource.getActiveDays();
    return dtos.map((e) => e.toEntity()).toList();
  }
}
