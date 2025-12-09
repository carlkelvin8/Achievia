// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/const.dart';
import 'package:achievia/data/models/reviewer/module_dto.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

abstract class ModuleRepositoryDataSource {
  Future<List<ModuleDto>> getModules(String token);
}

@injectable
@lazySingleton
class ModuleRemoteDatasource implements ModuleRepositoryDataSource {
  final Dio dio;

  ModuleRemoteDatasource({
    required this.dio,
  });

  @override
  Future<List<ModuleDto>> getModules(String token) async {
    try {
      final response = await dio.get(
        '$BASE_URL/reviewer/modules',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data']['data'] as List;
        return data.map((module) => ModuleDto.fromJson(module)).toList();
      } else {
        throw Exception('Failed to load modules: ${response.statusCode}');
      }
    } catch (e, st) {
      print('ModuleRemoteDatasource error: $e');
      print('Stack trace: $st');
      rethrow;
    }
  }
}
