import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/item_model.dart';
import '../../../../data/models/review_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/favorite_repository.dart';
import '../../../../data/repositories/item_repository.dart';

class ItemDetailState {
  final ItemModel item;
  final List<ReviewModel> reviews;
  final bool isFavorite;
  final bool isUpdatingFavorite;

  const ItemDetailState({
    required this.item,
    required this.reviews,
    required this.isFavorite,
    this.isUpdatingFavorite = false,
  });

  ItemDetailState copyWith({
    ItemModel? item,
    List<ReviewModel>? reviews,
    bool? isFavorite,
    bool? isUpdatingFavorite,
  }) {
    return ItemDetailState(
      item: item ?? this.item,
      reviews: reviews ?? this.reviews,
      isFavorite: isFavorite ?? this.isFavorite,
      isUpdatingFavorite: isUpdatingFavorite ?? this.isUpdatingFavorite,
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

  FavoriteRepository get _favoriteRepository =>
      ref.read(favoriteRepositoryProvider);

  @override
  FutureOr<ItemDetailState> build() async {
    final item = await _itemRepository.fetchItemDetail(itemId);

    List<ReviewModel> reviews = <ReviewModel>[];
    bool isFavorite = false;

    try {
      reviews = await _itemRepository.fetchItemReviews(itemId);
    } catch (_) {
      reviews = <ReviewModel>[];
    }

    try {
      final favoriteIds = await _favoriteRepository.fetchMyFavoriteItemIds();
      isFavorite = favoriteIds.contains(itemId);
    } catch (_) {
      isFavorite = false;
    }

    return ItemDetailState(
      item: item,
      reviews: reviews,
      isFavorite: isFavorite,
    );
  }

  Future<void> toggleFavorite() async {
    final current = state.value;

    if (current == null) return;

    state = AsyncData(current.copyWith(isUpdatingFavorite: true));

    try {
      if (current.isFavorite) {
        await _favoriteRepository.removeFavorite(current.item.id);
      } else {
        await _favoriteRepository.addFavorite(current.item.id);
      }

      state = AsyncData(
        current.copyWith(
          isFavorite: !current.isFavorite,
          isUpdatingFavorite: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isUpdatingFavorite: false));

      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    try {
      final item = await _itemRepository.fetchItemDetail(itemId);

      List<ReviewModel> reviews = <ReviewModel>[];
      bool isFavorite = false;

      try {
        reviews = await _itemRepository.fetchItemReviews(itemId);
      } catch (_) {
        reviews = <ReviewModel>[];
      }

      try {
        final favoriteIds = await _favoriteRepository.fetchMyFavoriteItemIds();
        isFavorite = favoriteIds.contains(itemId);
      } catch (_) {
        isFavorite = false;
      }

      state = AsyncData(
        ItemDetailState(item: item, reviews: reviews, isFavorite: isFavorite),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
