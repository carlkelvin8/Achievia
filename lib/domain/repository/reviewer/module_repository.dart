import 'package:achievia/domain/entities/api/reviewer/module_entity.dart';

abstract class ModuleRepository {
  Future<List<ModuleEntity>> getModules(String token);
}
