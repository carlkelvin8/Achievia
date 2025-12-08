import 'package:achievia/data/models/reviewer/module_dto.dart';
import 'package:hive/hive.dart';
import "package:injectable/injectable.dart";

abstract class ModuleCacheDataSource {
  Future<List<ModuleDto>> getCachedModules();
  Future<void> cacheModules(List<ModuleDto> modules);
}

@injectable
class ModuleCacheDataSourceImpl implements ModuleCacheDataSource {
  final Box<ModuleDto> box;
  
  ModuleCacheDataSourceImpl(@Named('module_box') this.box);

  @override
  Future<List<ModuleDto>> getCachedModules() async {
    return box.values.toList();
  }

  @override
  Future<void> cacheModules(List<ModuleDto> modules) async {
    await box.clear();
    for (var module in modules) {
      await box.put(module.id, module);
    }
  }
}
