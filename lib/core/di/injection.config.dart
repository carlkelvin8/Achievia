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
import 'package:achievia/core/network/offline_caching.dart' as _i64;
import 'package:achievia/core/registration/register_modules.dart' as _i790;
import 'package:achievia/data/data_source/auth/user_remote_datasource.dart'
    as _i528;
import 'package:achievia/data/data_source/cache/cache_data_source_impl.dart'
    as _i761;
import 'package:achievia/data/data_source/cache/mock_boards_questions_data_source.dart'
    as _i396;
import 'package:achievia/data/data_source/cache/module_cache_datasource.dart'
    as _i214;
import 'package:achievia/data/data_source/home/questions_remote_datasource.dart'
    as _i557;
import 'package:achievia/data/data_source/reviewer/module_remote_datasource.dart'
    as _i536;
import 'package:achievia/data/models/auth/user_dto.dart' as _i235;
import 'package:achievia/data/models/quiz/qotd_dto.dart' as _i900;
import 'package:achievia/data/models/quiz/questions_dto.dart' as _i74;
import 'package:achievia/data/models/reviewer/module_dto.dart' as _i862;
import 'package:achievia/data/repositoryImpl/auth/user_repository_impl.dart'
    as _i581;
import 'package:achievia/data/repositoryImpl/questions/qot_repository_impl.dart'
    as _i548;
import 'package:achievia/data/repositoryImpl/questions/questions_repository_impl.dart'
    as _i1000;
import 'package:achievia/data/repositoryImpl/reviewer/module_repository_impl.dart'
    as _i656;
import 'package:achievia/domain/entities/api/home/questions_entity.dart'
    as _i416;
import 'package:achievia/domain/use_cases/auth/user_use_case.dart' as _i879;
import 'package:achievia/domain/use_cases/questions/questions_use_case.dart'
    as _i803;
import 'package:achievia/domain/use_cases/reviewer/module_use_case.dart'
    as _i533;
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
    gh.lazySingleton<_i64.OfflineCaching>(() => _i64.OfflineCaching());
    gh.lazySingleton<_i982.LocalStorageService>(
      () => _i982.LocalStorageService(gh<_i460.SharedPreferences>()),
    );
    gh.factory<_i979.Box<dynamic>>(
      () => registerModules.exam,
      instanceName: 'exam_box',
    );
    await gh.factoryAsync<_i979.Box<_i900.QotdDto>>(
      () => hiveModule.openExamBox(),
      instanceName: 'exam_box',
      preResolve: true,
    );
    gh.factory<_i979.Box<dynamic>>(
      () => registerModules.questions,
      instanceName: 'questions_box',
    );
    gh.factory<_i979.Box<dynamic>>(
      () => registerModules.modules,
      instanceName: 'modules_box',
    );
    await gh.factoryAsync<_i979.Box<_i74.QuestionsDto>>(
      () => hiveModule.openQuestionBox(),
      instanceName: 'question_box',
      preResolve: true,
    );
    gh.lazySingleton<_i790.NetworkInfo>(
      () => _i790.NetworkInfoImpl(gh<_i895.Connectivity>()),
    );
    await gh.factoryAsync<_i979.Box<_i862.ModuleDto>>(
      () => hiveModule.openModuleBox(),
      instanceName: 'module_box',
      preResolve: true,
    );
    gh.factory<_i528.UserRemoteDatasource>(
      () => _i528.UserRemoteDatasource(dio: gh<_i361.Dio>()),
    );
    gh.factory<_i536.ModuleRemoteDatasource>(
      () => _i536.ModuleRemoteDatasource(dio: gh<_i361.Dio>()),
    );
    gh.factory<_i235.UserDto>(
      () => _i235.UserDto(
        id: gh<num>(),
        firstName: gh<String>(),
        middleName: gh<String>(),
        lastName: gh<String>(),
        bio: gh<String>(),
        age: gh<int>(),
        trial: gh<int>(),
        username: gh<String>(),
        email: gh<String>(),
        password: gh<String>(),
        role: gh<String>(),
        createdAt: gh<DateTime>(),
        updatedAt: gh<DateTime>(),
        status: gh<String>(),
        profileImage: gh<String>(),
        courseId: gh<int>(),
        token: gh<String>(),
      ),
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
    gh.factory<_i581.UserRepositoryImpl>(
      () => _i581.UserRepositoryImpl(
        datasource: gh<_i528.UserRemoteDatasource>(),
      ),
    );
    gh.factory<_i214.ModuleCacheDataSourceImpl>(
      () => _i214.ModuleCacheDataSourceImpl(
        gh<_i979.Box<_i862.ModuleDto>>(instanceName: 'module_box'),
      ),
    );
    gh.factory<_i396.MockBoardsQuestionsDataSourceImpl>(
      () => _i396.MockBoardsQuestionsDataSourceImpl(
        gh<_i979.Box<_i900.QotdDto>>(instanceName: 'exam_box'),
      ),
    );
    gh.factory<_i761.CacheDataSourceImpl>(
      () => _i761.CacheDataSourceImpl(
        gh<_i979.Box<_i74.QuestionsDto>>(instanceName: 'question_box'),
      ),
    );
    gh.factory<_i879.UserUseCase>(
      () => _i879.UserUseCase(impl: gh<_i581.UserRepositoryImpl>()),
    );
    gh.lazySingleton<_i557.QuestionsRemoteDatasource>(
      () => _i557.QuestionsRemoteDatasource(
        gh<_i361.Dio>(),
        gh<_i396.MockBoardsQuestionsDataSourceImpl>(),
      ),
    );
    gh.factory<_i656.ModuleRepositoryImpl>(
      () => _i656.ModuleRepositoryImpl(
        remoteDatasource: gh<_i536.ModuleRemoteDatasource>(),
        cacheDataSource: gh<_i214.ModuleCacheDataSourceImpl>(),
        network: gh<_i790.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i1000.QuestionsRepositoryImpl>(
      () => _i1000.QuestionsRepositoryImpl(
        gh<_i64.OfflineCaching>(),
        gh<_i557.QuestionsRemoteDatasource>(),
        gh<_i790.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i548.QotRepositoryImpl>(
      () => _i548.QotRepositoryImpl(
        remoteDatasource: gh<_i557.QuestionsRemoteDatasource>(),
        local: gh<_i761.CacheDataSourceImpl>(),
        network: gh<_i790.NetworkInfo>(),
      ),
    );
    gh.factory<_i533.ModuleUseCase>(
      () => _i533.ModuleUseCase(impl: gh<_i656.ModuleRepositoryImpl>()),
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
