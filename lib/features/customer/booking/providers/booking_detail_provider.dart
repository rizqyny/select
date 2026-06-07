import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/booking_model.dart';
import '../../../../data/models/payment_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/booking_repository.dart';
import '../../../../data/repositories/payment_repository.dart';

class BookingDetailState {
  final BookingModel booking;
  final PaymentModel? payment;
  final bool isCreatingPayment;
  final String? errorMessage;

  const BookingDetailState({
    required this.booking,
    this.payment,
    this.isCreatingPayment = false,
    this.errorMessage,
  });

  BookingDetailState copyWith({
    BookingModel? booking,
    Object? payment = _unset,
    bool? isCreatingPayment,
    Object? errorMessage = _unset,
  }) {
    return BookingDetailState(
      booking: booking ?? this.booking,
      payment: identical(payment, _unset)
          ? this.payment
          : payment as PaymentModel?,
      isCreatingPayment: isCreatingPayment ?? this.isCreatingPayment,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _unset = Object();

final bookingDetailControllerProvider =
    AsyncNotifierProvider.family<
      BookingDetailController,
      BookingDetailState,
      int
    >(BookingDetailController.new);

class BookingDetailController extends AsyncNotifier<BookingDetailState> {
  final int bookingId;

  BookingDetailController(this.bookingId);

  BookingRepository get _bookingRepository =>
      ref.read(bookingRepositoryProvider);

  PaymentRepository get _paymentRepository =>
      ref.read(paymentRepositoryProvider);

  @override
  FutureOr<BookingDetailState> build() async {
    final booking = await _bookingRepository.fetchBookingDetail(bookingId);
    final payment = await _paymentRepository.fetchPaymentByBooking(bookingId);

    return BookingDetailState(booking: booking, payment: payment);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final booking = await _bookingRepository.fetchBookingDetail(bookingId);
      final payment = await _paymentRepository.fetchPaymentByBooking(bookingId);

      return BookingDetailState(booking: booking, payment: payment);
    });
  }

  Future<PaymentModel?> createPayment() async {
    final current = state.value;

    if (current == null) return null;

    state = AsyncData(
      current.copyWith(isCreatingPayment: true, errorMessage: null),
    );

    try {
      final payment = await _paymentRepository.createPayment(
        current.booking.id,
      );

      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          payment: payment,
          isCreatingPayment: false,
          errorMessage: null,
        ),
      );

      return payment;
    } catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          isCreatingPayment: false,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      return null;
    }
  }
}
