import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/booking_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/booking_repository.dart';

class CustomerBookingsState {
  final List<BookingModel> bookings;
  final String? selectedStatus;

  const CustomerBookingsState({required this.bookings, this.selectedStatus});

  CustomerBookingsState copyWith({
    List<BookingModel>? bookings,
    Object? selectedStatus = _unset,
  }) {
    return CustomerBookingsState(
      bookings: bookings ?? this.bookings,
      selectedStatus: identical(selectedStatus, _unset)
          ? this.selectedStatus
          : selectedStatus as String?,
    );
  }
}

const Object _unset = Object();

final customerBookingsControllerProvider =
    AsyncNotifierProvider<CustomerBookingsController, CustomerBookingsState>(
      CustomerBookingsController.new,
    );

class CustomerBookingsController extends AsyncNotifier<CustomerBookingsState> {
  BookingRepository get _repository => ref.read(bookingRepositoryProvider);

  @override
  FutureOr<CustomerBookingsState> build() async {
    final bookings = await _repository.fetchMyBookings();

    return CustomerBookingsState(bookings: bookings);
  }

  Future<void> refresh() async {
    final current = state.value;

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final bookings = await _repository.fetchMyBookings(
        status: current?.selectedStatus,
      );

      return CustomerBookingsState(
        bookings: bookings,
        selectedStatus: current?.selectedStatus,
      );
    });
  }

  Future<void> setStatus(String? status) async {
    final current = state.value;

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final bookings = await _repository.fetchMyBookings(status: status);

      return CustomerBookingsState(bookings: bookings, selectedStatus: status);
    });

    if (state.hasError && current != null) {
      state = AsyncData(current);
    }
  }
}
