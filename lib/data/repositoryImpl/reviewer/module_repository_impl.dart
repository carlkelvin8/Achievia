// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/data/data_source/repository_data_source_impl/reviewer/module_remote_datasource.dart';
import 'package:achievia/domain/entities/api/reviewer/module_entity.dart';
import 'package:achievia/domain/repository/reviewer/module_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
@lazySingleton
class ModuleRepositoryImpl implements ModuleRepository {
  final ModuleRemoteDatasource datasource;

  ModuleRepositoryImpl({
    required this.datasource,
  });

  @override
  Future<List<ModuleEntity>> getModules(String token) async {
    try {
      final modules = await datasource.getModules(token);
      return modules.map((dto) => dto.toEntity()).toList();
    } catch (e, st) {
      print('ModuleRepositoryImpl error: $e');
      print('Stack trace: $st');
      rethrow;
    }
  }
}
