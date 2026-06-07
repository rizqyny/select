import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/availability_result.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../data/models/item_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/booking_repository.dart';
import '../../../../data/repositories/item_repository.dart';

const Object _unset = Object();

class CreateBookingState {
  final ItemModel item;
  final DateTime focusedDay;
  final DateTime? startDate;
  final DateTime? endDate;
  final String customerNote;
  final AvailabilityResult? availabilityResult;
  final BookingModel? createdBooking;
  final bool isCheckingAvailability;
  final bool isCreatingBooking;
  final String? errorMessage;

  const CreateBookingState({
    required this.item,
    required this.focusedDay,
    this.startDate,
    this.endDate,
    this.customerNote = '',
    this.availabilityResult,
    this.createdBooking,
    this.isCheckingAvailability = false,
    this.isCreatingBooking = false,
    this.errorMessage,
  });

  CreateBookingState copyWith({
    ItemModel? item,
    DateTime? focusedDay,
    Object? startDate = _unset,
    Object? endDate = _unset,
    String? customerNote,
    Object? availabilityResult = _unset,
    Object? createdBooking = _unset,
    bool? isCheckingAvailability,
    bool? isCreatingBooking,
    Object? errorMessage = _unset,
  }) {
    return CreateBookingState(
      item: item ?? this.item,
      focusedDay: focusedDay ?? this.focusedDay,
      startDate: identical(startDate, _unset)
          ? this.startDate
          : startDate as DateTime?,
      endDate: identical(endDate, _unset) ? this.endDate : endDate as DateTime?,
      customerNote: customerNote ?? this.customerNote,
      availabilityResult: identical(availabilityResult, _unset)
          ? this.availabilityResult
          : availabilityResult as AvailabilityResult?,
      createdBooking: identical(createdBooking, _unset)
          ? this.createdBooking
          : createdBooking as BookingModel?,
      isCheckingAvailability:
          isCheckingAvailability ?? this.isCheckingAvailability,
      isCreatingBooking: isCreatingBooking ?? this.isCreatingBooking,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  bool get hasValidDateRange => startDate != null && endDate != null;

  bool get canCreateBooking {
    return hasValidDateRange &&
        availabilityResult?.isAvailable == true &&
        !isCreatingBooking &&
        !isCheckingAvailability;
  }
}

final createBookingControllerProvider =
    AsyncNotifierProvider.family<
      CreateBookingController,
      CreateBookingState,
      int
    >(CreateBookingController.new);

class CreateBookingController extends AsyncNotifier<CreateBookingState> {
  final int itemId;

  CreateBookingController(this.itemId);

  ItemRepository get _itemRepository => ref.read(itemRepositoryProvider);

  BookingRepository get _bookingRepository =>
      ref.read(bookingRepositoryProvider);

  @override
  FutureOr<CreateBookingState> build() async {
    final item = await _itemRepository.fetchItemDetail(itemId);

    return CreateBookingState(
      item: item,
      focusedDay: _normalizeDate(DateTime.now()),
    );
  }

  void setDateRange({
    required DateTime? start,
    required DateTime? end,
    required DateTime focusedDay,
  }) {
    final current = state.value;

    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        startDate: start == null ? null : _normalizeDate(start),
        endDate: end == null ? null : _normalizeDate(end),
        focusedDay: _normalizeDate(focusedDay),
        availabilityResult: null,
        createdBooking: null,
        errorMessage: null,
      ),
    );
  }

  void setCustomerNote(String note) {
    final current = state.value;

    if (current == null) return;

    state = AsyncData(current.copyWith(customerNote: note, errorMessage: null));
  }

  Future<void> checkAvailability() async {
    final current = state.value;

    if (current == null) return;

    if (!current.hasValidDateRange) {
      state = AsyncData(
        current.copyWith(
          errorMessage:
              'Pilih tanggal mulai dan tanggal selesai terlebih dahulu.',
        ),
      );
      return;
    }

    state = AsyncData(
      current.copyWith(
        isCheckingAvailability: true,
        availabilityResult: null,
        createdBooking: null,
        errorMessage: null,
      ),
    );

    try {
      final result = await _bookingRepository.checkAvailability(
        itemIds: [current.item.id],
        rentalStartDate: current.startDate!,
        rentalEndDate: current.endDate!,
      );

      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          availabilityResult: result,
          isCheckingAvailability: false,
          errorMessage: null,
        ),
      );
    } catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          isCheckingAvailability: false,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<BookingModel?> createBooking() async {
    final current = state.value;

    if (current == null) return null;

    if (!current.hasValidDateRange) {
      state = AsyncData(
        current.copyWith(errorMessage: 'Tanggal sewa belum lengkap.'),
      );
      return null;
    }

    if (current.availabilityResult?.isAvailable != true) {
      state = AsyncData(
        current.copyWith(
          errorMessage: 'Cek ketersediaan terlebih dahulu sebelum booking.',
        ),
      );
      return null;
    }

    state = AsyncData(
      current.copyWith(isCreatingBooking: true, errorMessage: null),
    );

    try {
      final booking = await _bookingRepository.createBooking(
        itemIds: [current.item.id],
        rentalStartDate: current.startDate!,
        rentalEndDate: current.endDate!,
        customerNote: current.customerNote,
      );

      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          createdBooking: booking,
          isCreatingBooking: false,
          errorMessage: null,
        ),
      );

      return booking;
    } catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          isCreatingBooking: false,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      return null;
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
