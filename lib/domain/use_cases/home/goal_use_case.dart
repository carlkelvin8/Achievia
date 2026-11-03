import 'package:achievia/data/repositoryImpl/home/goal_repository_impl.dart';
import 'package:achievia/domain/entities/widgets/goal_entity.dart';
import 'package:injectable/injectable.dart';

@injectable
class GoalUseCase {
  final GoalRepositoryImpl repository;

  GoalUseCase(this.repository);

  Future<GoalEntity?> getTodayGoal() => repository.getTodayGoal();
  Future<void> saveTodayGoal(String title, String details) =>
      repository.saveTodayGoal(title, details);
  Future<void> clearGoal(String id) => repository.clearGoal(id);
  Future<void> setChecked(String id, bool checked) =>
      repository.setChecked(id, checked);
}
