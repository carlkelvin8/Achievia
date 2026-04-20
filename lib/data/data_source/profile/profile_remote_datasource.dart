import 'package:achievia/const.dart';
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/di/local_storage_service.dart';
import 'package:achievia/domain/entities/api/profile/profile_entity.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

abstract class ProfileDataSource {
  Future<ProfileEntity> getProfile();
  Future<String> updateMantra(String mantra);
}

@injectable
@lazySingleton
class ProfileRemoteDatasource implements ProfileDataSource {
  final Dio dio;

  ProfileRemoteDatasource({required this.dio});

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  @override
  Future<ProfileEntity> getProfile() async {
    final LocalStorageService storageService = sl<LocalStorageService>();
    final token = storageService.token;

    try {
      final response = await dio.get(
        '$BASE_URL/you/profile',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data']['data'];
        return ProfileEntity(
          id: data['id'],
          firstName: data['first_name'],
          middleName: data['middle_name'],
          lastName: data['last_name'],
          bio: data['bio'],
          email: data['email'],
          age: data['age'],
          trial: data['trial'],
          username: data['username'],
          role: data['role'],
          university: data['university'],
          purpose: data['purpose'],
          mantra: data['mantra'],
          dateOfExamination: _parseDate(
            data['date_of_examination'] ?? data['dateOfExamination'],
          ),
          createdAt: _parseDate(data['createdAt'] ?? data['created_at']),
          updatedAt: _parseDate(data['updatedAt'] ?? data['updated_at']),
          status: data['status'],
          profileImage: data['profile_image'],
          courseId: data['courseId'],
        );
      }

      throw Exception('Failed to fetch profile');
    } catch (e, st) {
      print('Error fetching profile: $e');
      print('Stack trace: $st');
      rethrow;
    }
  }

  @override
  Future<String> updateMantra(String mantra) async {
    final LocalStorageService storageService = sl<LocalStorageService>();
    final token = storageService.token;

    try {
      final response = await dio.put(
        '$BASE_URL/you/mantra',
        data: {'mantra': mantra},
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to update mantra');
      }

      final message = response.data?['data']?['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      return 'Mantra has been updated successfully';
    } catch (e, st) {
      print('Error updating mantra: $e');
      print('Stack trace: $st');

      if (e is DioException) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final backendMessage = errorData['error']?['message'];
          if (backendMessage is String && backendMessage.trim().isNotEmpty) {
            throw Exception(backendMessage);
          }
        }
      }

      rethrow;
    }
  }
}
