import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/di/local_storage_service.dart';
import 'package:achievia/data/models/progress/progress_day_dto.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

abstract class ProgressDataSource {
  Future<void> markTodayActive();
  Future<List<ProgressDayDto>> getActiveDays();
}

@lazySingleton
@injectable
class ProgressRemoteDatasource implements ProgressDataSource {
  final Dio dio;

  ProgressRemoteDatasource(this.dio);

  @override
  Future<void> markTodayActive() async {
    final LocalStorageService storageService = sl<LocalStorageService>();
    final token = storageService.token;

    await dio.post(
      '/progress/active',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  @override
  Future<List<ProgressDayDto>> getActiveDays() async {
    final LocalStorageService storageService = sl<LocalStorageService>();
    final token = storageService.token;

    final response = await dio.get(
      '/progress/read',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final data = response.data['data']['data'] as List<dynamic>;
    return data
        .map((item) => ProgressDayDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
