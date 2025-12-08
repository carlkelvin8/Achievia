// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/entities/api/reviewer/module_entity.dart';
import 'package:achievia/domain/use_cases/reviewer/module_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final getModules = Provider<ModuleUseCase>((ref) {
  return sl.get<ModuleUseCase>();
});

final getModulesProviderState = FutureProvider.family<List<ModuleEntity>, ({String token})>((ref, params) async {
  final moduleUseCase = ref.read(getModules);
  try {
    final result = await moduleUseCase.getModules(params.token);
    return result;
  } catch (e) {
    rethrow;
  }
});
