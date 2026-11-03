import 'package:achievia/domain/entities/widgets/goal_entity.dart';

abstract class GoalRepository {
  Future<GoalEntity?> getTodayGoal();
  Future<void> saveTodayGoal(String title, String details);
  Future<void> clearGoal(String id);
  Future<void> setChecked(String id, bool checked);
}
