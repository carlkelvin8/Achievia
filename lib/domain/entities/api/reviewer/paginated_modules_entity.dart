import 'package:achievia/domain/entities/api/reviewer/module_entity.dart';

class PaginatedModulesEntity {
  final List<ModuleEntity> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  PaginatedModulesEntity({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });
}
