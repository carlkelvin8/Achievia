import 'package:achievia/domain/entities/api/reviewer/paginated_modules_entity.dart';

abstract class ModuleRepository {
  Future<PaginatedModulesEntity> getModules(
    String token, {
    int page = 1,
    int limit = 20,
  });
}
