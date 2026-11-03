import 'package:achievia/domain/entities/widgets/daily_motivation_entity.dart';

abstract class DailyMotivationRepository {
  Future<DailyMotivationEntity?> getTodayMotivation({DateTime? now});
  Future<bool> isAdmin();
  Future<List<DailyMotivationEntity>> listAll();
  Future<void> add(String message);
  Future<void> edit(String id, String message);
  Future<void> setActive(String id, bool active);
  Future<void> delete(String id);
}
