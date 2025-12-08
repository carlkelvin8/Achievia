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
import 'package:achievia/core/network/conntectivity.dart' as _i790;
import 'package:achievia/core/network/dio_client.dart' as _i344;
import 'package:achievia/core/registration/register_modules.dart' as _i790;
import 'package:achievia/data/data_source/repository_data_source_impl/auth/user_remote_datasource.dart'
    as _i426;
import 'package:achievia/data/data_source/repository_data_source_impl/cache/cache_data_source_impl.dart'
    as _i692;
import 'package:achievia/data/data_source/repository_data_source_impl/home/questions_remote_datasource.dart'
    as _i322;
import 'package:achievia/data/models/quiz/questions_dto.dart' as _i74;
import 'package:achievia/data/repositoryImpl/auth/user_repository_impl.dart'
    as _i581;
import 'package:achievia/data/repositoryImpl/questions/qot_repository_impl.dart'
    as _i548;
import 'package:achievia/data/repositoryImpl/questions/questions_repository_impl.dart'
    as _i1000;
import 'package:achievia/domain/entities/api/home/questions_entity.dart'
    as _i416;
import 'package:achievia/domain/use_cases/auth/user_use_case.dart' as _i879;
import 'package:achievia/domain/use_cases/questions/questions_use_case.dart'
    as _i803;
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:hive/hive.dart' as _i979;
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
    final registerModules = _$RegisterModules();
    final hiveModule = _$HiveModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i344.DioClient>(() => _i344.DioClient());
    gh.lazySingleton<_i361.Dio>(() => registerModules.dio);
    gh.lazySingleton<_i895.Connectivity>(() => registerModules.connectivity);
    gh.lazySingleton<_i982.LocalStorageService>(
      () => _i982.LocalStorageService(gh<_i460.SharedPreferences>()),
    );
    gh.factory<_i979.Box<dynamic>>(
      () => registerModules.questions,
      instanceName: 'questions_box',
    );
    await gh.factoryAsync<_i979.Box<_i74.QuestionsDto>>(
      () => hiveModule.openQuestionBox(),
      instanceName: 'question_box',
      preResolve: true,
    );
    gh.lazySingleton<_i790.NetworkInfo>(
      () => _i790.NetworkInfoImpl(gh<_i895.Connectivity>()),
    );
    gh.lazySingleton<_i322.QuestionsRemoteDatasource>(
      () => _i322.QuestionsRemoteDatasource(gh<_i361.Dio>()),
    );
    gh.factory<_i416.QuestionsEntity>(
      () => _i416.QuestionsEntity(
        id: gh<String>(),
        title: gh<String>(),
        courseId: gh<String>(),
        description: gh<String>(),
        image: gh<String>(),
        day_subject: gh<String>(),
        createdAt: gh<String>(),
      ),
    );
    gh.factory<_i426.UserRemoteDatasource>(
      () => _i426.UserRemoteDatasource(dio: gh<_i361.Dio>()),
    );
    gh.factory<_i692.CacheDataSourceImpl>(
      () => _i692.CacheDataSourceImpl(
        gh<_i979.Box<_i74.QuestionsDto>>(instanceName: 'question_box'),
      ),
    );
    gh.factory<_i581.UserRepositoryImpl>(
      () => _i581.UserRepositoryImpl(
        datasource: gh<_i426.UserRemoteDatasource>(),
      ),
    );
    gh.factory<_i879.UserUseCase>(
      () => _i879.UserUseCase(impl: gh<_i581.UserRepositoryImpl>()),
    );
    gh.lazySingleton<_i548.QotRepositoryImpl>(
      () => _i548.QotRepositoryImpl(
        remoteDatasource: gh<_i322.QuestionsRemoteDatasource>(),
        local: gh<_i692.CacheDataSourceImpl>(),
        network: gh<_i790.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i1000.QuestionsRepositoryImpl>(
      () => _i1000.QuestionsRepositoryImpl(
        gh<_i692.CacheDataSourceImpl>(),
        gh<_i322.QuestionsRemoteDatasource>(),
        gh<_i790.NetworkInfo>(),
      ),
    );
    gh.factory<_i803.QuestionsUseCase>(
      () => _i803.QuestionsUseCase(
        gh<_i1000.QuestionsRepositoryImpl>(),
        gh<_i548.QotRepositoryImpl>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i644.RegisterModule {}

class _$RegisterModules extends _i790.RegisterModules {}

class _$HiveModule extends _i790.HiveModule {}
