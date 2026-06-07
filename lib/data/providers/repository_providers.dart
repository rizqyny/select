import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../repositories/booking_repository.dart';
import '../repositories/favorite_repository.dart';
import '../repositories/item_repository.dart';
import '../repositories/payment_repository.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(dio: ref.watch(dioProvider));
});

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(dio: ref.watch(dioProvider));
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(dio: ref.watch(dioProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(dio: ref.watch(dioProvider));
});
