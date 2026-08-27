import 'package:achievia/domain/entities/widgets/goal_entity.dart';

abstract class GoalRepository {
  Future<GoalEntity?> getTodayGoal();
  Future<void> setChecked(String id, bool checked);
}
