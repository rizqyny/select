import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/admin_identity_verification_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/admin_verification_repository.dart';
import '../../../../data/repositories/storage_repository.dart';

const Object _unset = Object();

class AdminIdentityVerificationsState {
  final List<AdminIdentityVerificationModel> verifications;
  final String? selectedStatus;
  final int? updatingId;
  final String? errorMessage;

  const AdminIdentityVerificationsState({
    required this.verifications,
    this.selectedStatus,
    this.updatingId,
    this.errorMessage,
  });

  AdminIdentityVerificationsState copyWith({
    List<AdminIdentityVerificationModel>? verifications,
    Object? selectedStatus = _unset,
    Object? updatingId = _unset,
    Object? errorMessage = _unset,
  }) {
    return AdminIdentityVerificationsState(
      verifications: verifications ?? this.verifications,
      selectedStatus: identical(selectedStatus, _unset)
          ? this.selectedStatus
          : selectedStatus as String?,
      updatingId: identical(updatingId, _unset)
          ? this.updatingId
          : updatingId as int?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

final adminIdentityVerificationsControllerProvider =
    AsyncNotifierProvider<
      AdminIdentityVerificationsController,
      AdminIdentityVerificationsState
    >(AdminIdentityVerificationsController.new);

class AdminIdentityVerificationsController
    extends AsyncNotifier<AdminIdentityVerificationsState> {
  AdminVerificationRepository get _repository =>
      ref.read(adminVerificationRepositoryProvider);

  @override
  FutureOr<AdminIdentityVerificationsState> build() async {
    final verifications = await _repository.fetchIdentityVerifications();

    return AdminIdentityVerificationsState(verifications: verifications);
  }

  Future<void> refresh() async {
    final current = state.value;

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final verifications = await _repository.fetchIdentityVerifications(
        status: current?.selectedStatus,
      );

      return AdminIdentityVerificationsState(
        verifications: verifications,
        selectedStatus: current?.selectedStatus,
      );
    });
  }

  Future<void> setStatus(String? status) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final verifications = await _repository.fetchIdentityVerifications(
        status: status,
      );

      return AdminIdentityVerificationsState(
        verifications: verifications,
        selectedStatus: status,
      );
    });
  }

  Future<bool> approve(int id) async {
    final current = state.value;

    if (current == null) return false;

    state = AsyncData(current.copyWith(updatingId: id, errorMessage: null));

    try {
      await _repository.approveIdentityVerification(id);
      await refresh();
      return true;
    } catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          updatingId: null,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      return false;
    }
  }

  Future<bool> reject({required int id, required String reason}) async {
    final current = state.value;

    if (current == null) return false;

    state = AsyncData(current.copyWith(updatingId: id, errorMessage: null));

    try {
      await _repository.rejectIdentityVerification(id: id, reason: reason);

      await refresh();
      return true;
    } catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          updatingId: null,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      return false;
    }
  }
}

final adminIdentityDocumentUrlProvider = FutureProvider.family<String, String>((
  ref,
  photoPath,
) async {
  if (photoPath.trim().isEmpty) return '';

  final StorageRepository storageRepository = ref.read(
    storageRepositoryProvider,
  );

  return storageRepository.createSignedReadUrl(
    bucket: 'identity-documents',
    path: photoPath,
  );
});

final adminIdentityVerificationByBookingProvider =
    FutureProvider.family<AdminIdentityVerificationModel?, int>((
      ref,
      bookingId,
    ) async {
      final repository = ref.read(adminVerificationRepositoryProvider);

      final verifications = await repository.fetchIdentityVerifications(
        page: 1,
        limit: 100,
      );

      for (final verification in verifications) {
        if (verification.bookingId == bookingId) {
          return verification;
        }
      }

      return null;
    });
