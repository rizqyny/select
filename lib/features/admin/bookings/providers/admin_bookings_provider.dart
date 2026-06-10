import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/admin_booking_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/admin_booking_repository.dart';

const Object _unset = Object();

class AdminBookingsState {
  final List<AdminBookingModel> bookings;
  final String? selectedStatus;
  final int? updatingId;
  final String? errorMessage;

  const AdminBookingsState({
    required this.bookings,
    this.selectedStatus,
    this.updatingId,
    this.errorMessage,
  });

  AdminBookingsState copyWith({
    List<AdminBookingModel>? bookings,
    Object? selectedStatus = _unset,
    Object? updatingId = _unset,
    Object? errorMessage = _unset,
  }) {
    return AdminBookingsState(
      bookings: bookings ?? this.bookings,
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

final adminBookingsControllerProvider =
    AsyncNotifierProvider<AdminBookingsController, AdminBookingsState>(
      AdminBookingsController.new,
    );

class AdminBookingsController extends AsyncNotifier<AdminBookingsState> {
  AdminBookingRepository get _repository =>
      ref.read(adminBookingRepositoryProvider);

  @override
  FutureOr<AdminBookingsState> build() async {
    final bookings = await _repository.fetchAdminBookings();

    return AdminBookingsState(bookings: bookings);
  }

  Future<void> refresh() async {
    final current = state.value;

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final bookings = await _repository.fetchAdminBookings(
        status: current?.selectedStatus,
      );

      return AdminBookingsState(
        bookings: bookings,
        selectedStatus: current?.selectedStatus,
      );
    });
  }

  Future<void> setStatus(String? status) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final bookings = await _repository.fetchAdminBookings(status: status);

      return AdminBookingsState(bookings: bookings, selectedStatus: status);
    });
  }

  Future<bool> approve(int id) async {
    return _runAction(id: id, action: () => _repository.approveBooking(id));
  }

  Future<bool> reject({required int id, required String reason}) async {
    return _runAction(
      id: id,
      action: () => _repository.rejectBooking(id: id, reason: reason),
    );
  }

  Future<bool> start(int id) async {
    return _runAction(id: id, action: () => _repository.startBooking(id));
  }

  Future<bool> complete(int id) async {
    return _runAction(id: id, action: () => _repository.completeBooking(id));
  }

  Future<bool> _runAction({
    required int id,
    required Future<void> Function() action,
  }) async {
    final current = state.value;

    if (current == null) return false;

    state = AsyncData(current.copyWith(updatingId: id, errorMessage: null));

    try {
      await action();
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
