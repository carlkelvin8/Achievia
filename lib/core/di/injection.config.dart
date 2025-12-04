// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:achievia/core/di/local_storage_service.dart' as _i982;
import 'package:achievia/core/di/shared_pref.dart' as _i644;
import 'package:achievia/data/data_source/repository_data_source_impl/home/questions_remote_datasource.dart'
    as _i322;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.singleton<_i982.LocalStorageService>(
      () => _i982.LocalStorageService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i322.QuestionRepoDataSource>(
      () => _i322.QuestionsRemoteDatasource(),
    );
    return this;
  }
}

class _$RegisterModule extends _i644.RegisterModule {}
