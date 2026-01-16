import 'package:achievia/core/di/injection.dart';
import 'package:achievia/data/repositoryImpl/profile/profile_repository_impl.dart';
import 'package:achievia/domain/entities/api/profile/profile_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileState {
  final ProfileEntity? profile;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    ProfileEntity? profile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    return const ProfileState();
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = sl<ProfileRepositoryImpl>();
      final profile = await repository.getProfile();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearProfile() {
    state = const ProfileState();
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  () => ProfileNotifier(),
);
