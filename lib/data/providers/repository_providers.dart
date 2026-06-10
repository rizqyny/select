import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../repositories/booking_repository.dart';
import '../repositories/favorite_repository.dart';
import '../repositories/item_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/storage_repository.dart';
import '../repositories/verification_repository.dart';
import '../repositories/admin_verification_repository.dart';
import '../repositories/admin_booking_repository.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(dio: ref.watch(dioProvider));
});

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(dio: ref.watch(dioProvider));
});

// final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
//   return BookingRepository(dio: ref.watch(dioProvider));
// });

// final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
//   return PaymentRepository(dio: ref.watch(dioProvider));
// });

final adminVerificationRepositoryProvider =
    Provider<AdminVerificationRepository>((ref) {
      return AdminVerificationRepository(dio: ref.watch(dioProvider));
    });

final adminBookingRepositoryProvider = Provider<AdminBookingRepository>((ref) {
  return AdminBookingRepository(dio: ref.watch(dioProvider));
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(dio: ref.watch(dioProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(dio: ref.watch(dioProvider));
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(dio: ref.watch(dioProvider));
});

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepository(dio: ref.watch(dioProvider));
});
