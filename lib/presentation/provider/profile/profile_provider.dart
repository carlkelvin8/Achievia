// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/di/local_storage_service.dart';
import 'package:achievia/domain/entities/api/profile/profile_entity.dart';
import 'package:achievia/domain/use_cases/profile/profile_use_case.dart';
import 'package:achievia/presentation/provider/profile/profile_view_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for ProfileUseCase
final profileUseCaseProvider = Provider<ProfileUseCase>((ref) {
  return sl<ProfileUseCase>();
});

// FutureProvider for profile data
final profileProvider = FutureProvider<ProfileEntity>((ref) async {
  final useCase = ref.read(profileUseCaseProvider);
  final profile = await useCase.getProfile();

  // Auto-patch purpose for existing accounts that signed up before the fix
  if (profile.purpose == null || profile.purpose!.trim().isEmpty) {
    // Best effort: a failed write must not turn a successful profile fetch
    // into an error state, so the default is still applied locally.
    try {
      await useCase.updatePurpose('MTLE');
    } catch (error) {
      debugPrint('Profile purpose auto-patch failed: $error');
    }
    return profile.copyWith(purpose: 'MTLE');
  }

  return profile;
});

final updateMantraProvider =
    AsyncNotifierProvider<UpdateMantraNotifier, String?>(
      UpdateMantraNotifier.new,
    );

class UpdateMantraNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<String> updateMantra(String mantra) async {
    state = const AsyncLoading();
    try {
      final message = await ref
          .read(profileUseCaseProvider)
          .updateMantra(mantra);
      state = AsyncData(message);
      ref.invalidate(profileProvider);
      return message;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

class BoardExamDateNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    return sl<LocalStorageService>().boardExamDate;
  }

  /// Saves the date on the profile first; the device copy and the screen only
  /// change once the server accepted it, so a failed save never leaves a date
  /// that exists on this device alone. Throws when the save fails.
  Future<void> setDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final safeDate = normalized.isBefore(todayOnly) ? todayOnly : normalized;
    await ref.read(profileUseCaseProvider).updateExamDate(safeDate);
    await sl<LocalStorageService>().saveBoardExamDate(safeDate);
    state = safeDate;
    ref.invalidate(profileProvider);
  }
}

final boardExamDateProvider =
    NotifierProvider<BoardExamDateNotifier, DateTime?>(
      BoardExamDateNotifier.new,
    );

final profileScreenViewProvider = Provider<AsyncValue<ProfileScreenViewData>>((
  ref,
) {
  final profileAsync = ref.watch(profileProvider);
  final selectedBoardExamDate = ref.watch(boardExamDateProvider);
  return profileAsync.whenData(
    (profile) => ProfileScreenViewData.fromEntity(
      profile,
      selectedBoardExamDate: selectedBoardExamDate,
    ),
  );
});
