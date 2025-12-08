// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/data/repositoryImpl/reviewer/module_repository_impl.dart';
import 'package:achievia/domain/entities/api/reviewer/module_entity.dart';
import 'package:injectable/injectable.dart';

@injectable
class ModuleUseCase {
  final ModuleRepositoryImpl impl;

  ModuleUseCase({
    required this.impl,
  });

  Future<List<ModuleEntity>> getModules(String token) async => await impl.getModules(token);
}
