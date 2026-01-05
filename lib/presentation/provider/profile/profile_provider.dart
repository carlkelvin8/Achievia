// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/di/local_storage_service.dart';
import 'package:achievia/domain/entities/api/auth/user_entity.dart';
import 'package:achievia/domain/use_cases/auth/user_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for UserUseCase
final profileUseCaseProvider = Provider<UserUseCase>((ref) {
  return sl<UserUseCase>();
});

// Provider for LocalStorageService
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return sl<LocalStorageService>();
});

// FutureProvider for profile data
final profileProvider = FutureProvider<UserEntity>((ref) async {
  final useCase = ref.read(profileUseCaseProvider);
  final storageService = ref.read(localStorageServiceProvider);

  final token = storageService.token;
  if (token == null || token.isEmpty) {
    throw Exception('No authentication token found');
  }

  try {
    final profile = await useCase.getProfile(token);
    return profile;
  } catch (e) {
    throw Exception('Failed to fetch profile: $e');
  }
});
