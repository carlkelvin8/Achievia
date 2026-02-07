import 'package:achievia/const.dart';
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/di/local_storage_service.dart';
import 'package:achievia/domain/entities/api/profile/profile_entity.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

abstract class ProfileDataSource {
  Future<ProfileEntity> getProfile();
}

@injectable
@lazySingleton
class ProfileRemoteDatasource implements ProfileDataSource {
  final Dio dio;

  ProfileRemoteDatasource({required this.dio});

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
          dateOfExamination: data['date_of_examination'] != null
              ? DateTime.parse(data['date_of_examination'])
              : null,
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'])
              : null,
          updatedAt: data['updatedAt'] != null
              ? DateTime.parse(data['updatedAt'])
              : null,
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
}
