import 'package:achievia/data/data_source/home/goal_remote_datasource.dart';
import 'package:achievia/domain/entities/widgets/goal_entity.dart';
import 'package:achievia/domain/repository/home/goal_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
@injectable
class GoalRepositoryImpl implements GoalRepository {
  final GoalRemoteDatasource datasource;

  GoalRepositoryImpl(this.datasource);

  @override
  Future<GoalEntity?> getTodayGoal() async =>
      (await datasource.getTodayGoal())?.toEntity();

  @override
  Future<void> saveTodayGoal(String title, String details) =>
      datasource.saveTodayGoal(title, details);

  @override
  Future<void> clearGoal(String id) => datasource.clearGoal(id);

  @override
  Future<void> setChecked(String id, bool checked) =>
      datasource.setChecked(id, checked);
}
