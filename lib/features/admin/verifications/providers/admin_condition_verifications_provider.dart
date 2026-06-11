import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/admin_condition_verification_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/admin_condition_verification_repository.dart';

const Object _unset = Object();

class AdminConditionVerificationsState {
  final List<AdminConditionVerificationModel> verifications;
  final int? updatingId;
  final String? errorMessage;

  const AdminConditionVerificationsState({
    required this.verifications,
    this.updatingId,
    this.errorMessage,
  });

  AdminConditionVerificationsState copyWith({
    List<AdminConditionVerificationModel>? verifications,
    Object? updatingId = _unset,
    Object? errorMessage = _unset,
  }) {
    return AdminConditionVerificationsState(
      verifications: verifications ?? this.verifications,
      updatingId: identical(updatingId, _unset)
          ? this.updatingId
          : updatingId as int?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

final adminConditionVerificationsControllerProvider =
    AsyncNotifierProvider<
      AdminConditionVerificationsController,
      AdminConditionVerificationsState
    >(AdminConditionVerificationsController.new);

class AdminConditionVerificationsController
    extends AsyncNotifier<AdminConditionVerificationsState> {
  AdminConditionVerificationRepository get _repository =>
      ref.read(adminConditionVerificationRepositoryProvider);

  @override
  FutureOr<AdminConditionVerificationsState> build() async {
    final verifications = await _repository.fetchConditionVerifications();

    return AdminConditionVerificationsState(verifications: verifications);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final verifications = await _repository.fetchConditionVerifications();

      return AdminConditionVerificationsState(verifications: verifications);
    });
  }

  Future<bool> startRent({
    required int verificationId,
    required int bookingId,
  }) async {
    final current = state.value;

    if (current == null) return false;

    state = AsyncData(
      current.copyWith(updatingId: verificationId, errorMessage: null),
    );

    try {
      await _repository.approveConditionAndStartBooking(
        verificationId: verificationId,
        bookingId: bookingId,
      );

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

  Future<bool> reject({
    required int verificationId,
    required String reason,
  }) async {
    final current = state.value;

    if (current == null) return false;

    state = AsyncData(
      current.copyWith(updatingId: verificationId, errorMessage: null),
    );

    try {
      await _repository.rejectCondition(id: verificationId, reason: reason);

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
