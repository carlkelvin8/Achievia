// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/data/repositoryImpl/reviewer/module_repository_impl.dart';
import 'package:achievia/domain/entities/api/reviewer/paginated_modules_entity.dart';
import 'package:injectable/injectable.dart';

@injectable
class ModuleUseCase {
  final ModuleRepositoryImpl impl;

  ModuleUseCase({
    required this.impl,
  });

  Future<PaginatedModulesEntity> getModules(
    String token, {
    int page = 1,
    int limit = 20,
  }) async => await impl.getModules(token, page: page, limit: limit);
}
