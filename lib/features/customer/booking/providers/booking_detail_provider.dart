import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/models/booking_model.dart';
import '../../../../data/models/payment_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/booking_repository.dart';
import '../../../../data/repositories/payment_repository.dart';

const Object _unset = Object();

class BookingDetailState {
  final BookingModel booking;
  final PaymentModel? payment;
  final bool isCreatingPayment;
  final bool hasSubmittedIdentityVerification;
  final bool hasSubmittedBeforeConditionVerification;
  final bool hasSubmittedAfterConditionVerification;
  final bool hasSubmittedReview;
  final String? errorMessage;

  const BookingDetailState({
    required this.booking,
    this.payment,
    this.isCreatingPayment = false,
    this.hasSubmittedIdentityVerification = false,
    this.hasSubmittedBeforeConditionVerification = false,
    this.hasSubmittedAfterConditionVerification = false,
    this.hasSubmittedReview = false,
    this.errorMessage,
  });

  BookingDetailState copyWith({
    BookingModel? booking,
    Object? payment = _unset,
    bool? isCreatingPayment,
    bool? hasSubmittedIdentityVerification,
    bool? hasSubmittedBeforeConditionVerification,
    bool? hasSubmittedAfterConditionVerification,
    bool? hasSubmittedReview,
    Object? errorMessage = _unset,
  }) {
    return BookingDetailState(
      booking: booking ?? this.booking,
      payment: identical(payment, _unset)
          ? this.payment
          : payment as PaymentModel?,
      isCreatingPayment: isCreatingPayment ?? this.isCreatingPayment,
      hasSubmittedIdentityVerification:
          hasSubmittedIdentityVerification ??
          this.hasSubmittedIdentityVerification,
      hasSubmittedBeforeConditionVerification:
          hasSubmittedBeforeConditionVerification ??
          this.hasSubmittedBeforeConditionVerification,
      hasSubmittedAfterConditionVerification:
          hasSubmittedAfterConditionVerification ??
          this.hasSubmittedAfterConditionVerification,
      hasSubmittedReview: hasSubmittedReview ?? this.hasSubmittedReview,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

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

  String get _localIdentityKey => 'identity_verification_submitted_$bookingId';

  @override
  FutureOr<BookingDetailState> build() async {
    final booking = await _bookingRepository.fetchBookingDetail(bookingId);
    final payment = await _paymentRepository.fetchPaymentByBooking(bookingId);

    final localIdentitySubmitted = await _getLocalIdentitySubmitted();

    final itemId = _firstItemId(booking);

    final localBeforeConditionSubmitted = await _getLocalConditionSubmitted(
      bookingId: booking.id,
      itemId: itemId,
      type: 'before_rent',
    );

    final localAfterConditionSubmitted = await _getLocalConditionSubmitted(
      bookingId: booking.id,
      itemId: itemId,
      type: 'after_rent',
    );

    final localReviewSubmitted = await _getLocalReviewSubmitted(
      bookingId: booking.id,
      itemId: itemId,
    );

    return BookingDetailState(
      booking: booking,
      payment: payment,
      hasSubmittedIdentityVerification:
          localIdentitySubmitted || booking.hasIdentityVerification,
      hasSubmittedBeforeConditionVerification: localBeforeConditionSubmitted,
      hasSubmittedAfterConditionVerification: localAfterConditionSubmitted,
      hasSubmittedReview: localReviewSubmitted,
    );
  }

  Future<void> refresh() async {
    final current = state.value;

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final booking = await _bookingRepository.fetchBookingDetail(bookingId);
      final payment = await _paymentRepository.fetchPaymentByBooking(bookingId);

      final localIdentitySubmitted = await _getLocalIdentitySubmitted();

      final itemId = _firstItemId(booking);

      final localBeforeConditionSubmitted = await _getLocalConditionSubmitted(
        bookingId: booking.id,
        itemId: itemId,
        type: 'before_rent',
      );

      final localAfterConditionSubmitted = await _getLocalConditionSubmitted(
        bookingId: booking.id,
        itemId: itemId,
        type: 'after_rent',
      );

      final localReviewSubmitted = await _getLocalReviewSubmitted(
        bookingId: booking.id,
        itemId: itemId,
      );

      return BookingDetailState(
        booking: booking,
        payment: payment,
        hasSubmittedIdentityVerification:
            localIdentitySubmitted ||
            booking.hasIdentityVerification ||
            (current?.hasSubmittedIdentityVerification ?? false),
        hasSubmittedBeforeConditionVerification:
            localBeforeConditionSubmitted ||
            (current?.hasSubmittedBeforeConditionVerification ?? false),
        hasSubmittedAfterConditionVerification:
            localAfterConditionSubmitted ||
            (current?.hasSubmittedAfterConditionVerification ?? false),
        hasSubmittedReview:
            localReviewSubmitted || (current?.hasSubmittedReview ?? false),
      );
    });
  }

  Future<void> markIdentityVerificationSubmitted() async {
    final current = state.value;

    await _setLocalIdentitySubmitted(true);

    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        hasSubmittedIdentityVerification: true,
        errorMessage: null,
      ),
    );
  }

  Future<void> markConditionVerificationSubmitted(String type) async {
    final current = state.value;

    if (current == null) return;

    final itemId = _firstItemId(current.booking);

    await _setLocalConditionSubmitted(
      bookingId: current.booking.id,
      itemId: itemId,
      type: 'before_rent',
      value: true,
    );

    state = AsyncData(
      current.copyWith(
        hasSubmittedBeforeConditionVerification: true,
        errorMessage: null,
      ),
    );
  }

  Future<void> markReviewSubmitted() async {
    final current = state.value;

    if (current == null) return;

    final itemId = _firstItemId(current.booking);

    await _setLocalReviewSubmitted(
      bookingId: current.booking.id,
      itemId: itemId,
      value: true,
    );

    state = AsyncData(
      current.copyWith(hasSubmittedReview: true, errorMessage: null),
    );
  }

  Future<PaymentModel?> createPayment() async {
    final current = state.value;

    if (current == null) return null;

    if (!current.booking.canPay) {
      state = AsyncData(
        current.copyWith(
          errorMessage:
              'Pembayaran baru bisa dilakukan setelah verifikasi KTP disetujui admin.',
        ),
      );
      return null;
    }

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

  int _firstItemId(BookingModel booking) {
    if (booking.items.isEmpty) return 0;

    return booking.items.first.itemId;
  }

  Future<bool> _getLocalIdentitySubmitted() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_localIdentityKey) ?? false;
  }

  Future<void> _setLocalIdentitySubmitted(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_localIdentityKey, value);
  }

  String _localConditionKey({
    required int bookingId,
    required int itemId,
    required String type,
  }) {
    return 'condition_verification_${bookingId}_${itemId}_$type';
  }

  Future<bool> _getLocalConditionSubmitted({
    required int bookingId,
    required int itemId,
    required String type,
  }) async {
    if (itemId == 0) return false;

    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(
          _localConditionKey(bookingId: bookingId, itemId: itemId, type: type),
        ) ??
        false;
  }

  Future<void> _setLocalConditionSubmitted({
    required int bookingId,
    required int itemId,
    required String type,
    required bool value,
  }) async {
    if (itemId == 0) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      _localConditionKey(bookingId: bookingId, itemId: itemId, type: type),
      value,
    );
  }

  String _localReviewKey({required int bookingId, required int itemId}) {
    return 'review_submitted_${bookingId}_$itemId';
  }

  Future<bool> _getLocalReviewSubmitted({
    required int bookingId,
    required int itemId,
  }) async {
    if (itemId == 0) return false;

    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(
          _localReviewKey(bookingId: bookingId, itemId: itemId),
        ) ??
        false;
  }

  Future<void> _setLocalReviewSubmitted({
    required int bookingId,
    required int itemId,
    required bool value,
  }) async {
    if (itemId == 0) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      _localReviewKey(bookingId: bookingId, itemId: itemId),
      value,
    );
  }

  Future<PaymentModel?> simulatePaymentPaid() async {
    final current = state.value;

    if (current == null) return null;

    state = AsyncData(
      current.copyWith(isCreatingPayment: true, errorMessage: null),
    );

    try {
      final payment = await _paymentRepository.simulatePaymentPaidByBooking(
        current.booking.id,
      );

      final latestBooking = await _bookingRepository.fetchBookingDetail(
        current.booking.id,
      );

      state = AsyncData(
        current.copyWith(
          booking: latestBooking,
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
