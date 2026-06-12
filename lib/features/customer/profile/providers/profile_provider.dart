import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/profile_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/profile_repository.dart';

const Object _unset = Object();

class ProfileState {
  final ProfileModel profile;
  final bool isUpdating;
  final String? errorMessage;
  final String? successMessage;

  const ProfileState({
    required this.profile,
    this.isUpdating = false,
    this.errorMessage,
    this.successMessage,
  });

  ProfileState copyWith({
    ProfileModel? profile,
    bool? isUpdating,
    Object? errorMessage = _unset,
    Object? successMessage = _unset,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: identical(successMessage, _unset)
          ? this.successMessage
          : successMessage as String?,
    );
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileState>(
      ProfileController.new,
    );

class ProfileController extends AsyncNotifier<ProfileState> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  FutureOr<ProfileState> build() async {
    final profile = await _repository.fetchMyProfile();

    return ProfileState(profile: profile);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final profile = await _repository.fetchMyProfile();

      return ProfileState(profile: profile);
    });
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final current = state.value;

    if (current == null) return false;

    if (fullName.trim().isEmpty) {
      state = AsyncData(
        current.copyWith(
          errorMessage: 'Nama lengkap tidak boleh kosong.',
          successMessage: null,
        ),
      );
      return false;
    }

    state = AsyncData(
      current.copyWith(
        isUpdating: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      final updatedProfile = await _repository.updateMyProfile(
        fullName: fullName,
        phone: phone,
      );

      state = AsyncData(
        current.copyWith(
          profile: updatedProfile,
          isUpdating: false,
          errorMessage: null,
          successMessage: 'Profil berhasil diperbarui.',
        ),
      );

      return true;
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isUpdating: false,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
          successMessage: null,
        ),
      );

      return false;
    }
  }
}
