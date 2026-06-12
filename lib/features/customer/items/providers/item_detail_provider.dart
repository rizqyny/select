import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/item_model.dart';
import '../../../../data/models/review_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/favorite_repository.dart';
import '../../../../data/repositories/item_repository.dart';
import '../../../../data/repositories/review_repository.dart';

class ItemDetailState {
  final ItemModel item;
  final List<ReviewModel> reviews;
  final bool isFavorite;
  final bool isUpdatingFavorite;
  final String? errorMessage;

  const ItemDetailState({
    required this.item,
    required this.reviews,
    required this.isFavorite,
    this.isUpdatingFavorite = false,
    this.errorMessage,
  });

  ItemDetailState copyWith({
    ItemModel? item,
    List<ReviewModel>? reviews,
    bool? isFavorite,
    bool? isUpdatingFavorite,
    String? errorMessage,
  }) {
    return ItemDetailState(
      item: item ?? this.item,
      reviews: reviews ?? this.reviews,
      isFavorite: isFavorite ?? this.isFavorite,
      isUpdatingFavorite: isUpdatingFavorite ?? this.isUpdatingFavorite,
      errorMessage: errorMessage,
    );
  }
}

final itemDetailControllerProvider =
    AsyncNotifierProvider.family<ItemDetailController, ItemDetailState, int>(
      ItemDetailController.new,
    );

class ItemDetailController extends AsyncNotifier<ItemDetailState> {
  final int itemId;

  ItemDetailController(this.itemId);

  ItemRepository get _itemRepository => ref.read(itemRepositoryProvider);

  ReviewRepository get _reviewRepository => ref.read(reviewRepositoryProvider);

  FavoriteRepository get _favoriteRepository =>
      ref.read(favoriteRepositoryProvider);

  @override
  FutureOr<ItemDetailState> build() async {
    final item = await _itemRepository.fetchItemDetail(itemId);
    final reviews = await _fetchReviewsSafely();
    final isFavorite = await _fetchFavoriteStatusSafely();

    return ItemDetailState(
      item: item,
      reviews: reviews,
      isFavorite: isFavorite,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final item = await _itemRepository.fetchItemDetail(itemId);
      final reviews = await _fetchReviewsSafely();
      final isFavorite = await _fetchFavoriteStatusSafely();

      return ItemDetailState(
        item: item,
        reviews: reviews,
        isFavorite: isFavorite,
      );
    });
  }

  Future<void> toggleFavorite() async {
    final current = state.value;

    if (current == null) return;

    state = AsyncData(
      current.copyWith(isUpdatingFavorite: true, errorMessage: null),
    );

    try {
      if (current.isFavorite) {
        await _favoriteRepository.removeFavorite(current.item.id);
      } else {
        await _favoriteRepository.addFavorite(current.item.id);
      }

      final latestIsFavorite = await _fetchFavoriteStatusSafely();

      state = AsyncData(
        current.copyWith(
          isFavorite: latestIsFavorite,
          isUpdatingFavorite: false,
          errorMessage: null,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isUpdatingFavorite: false,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      rethrow;
    }
  }

  Future<List<ReviewModel>> _fetchReviewsSafely() async {
    try {
      return await _reviewRepository.fetchItemReviews(itemId);
    } catch (_) {
      return <ReviewModel>[];
    }
  }

  Future<bool> _fetchFavoriteStatusSafely() async {
    try {
      final favorites = await _favoriteRepository.fetchMyFavorites();

      return favorites.any((favorite) => favorite.itemId == itemId);
    } catch (_) {
      return false;
    }
  }
}
