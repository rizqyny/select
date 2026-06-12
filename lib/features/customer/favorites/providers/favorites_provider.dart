import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/favorite_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/favorite_repository.dart';

const Object _unset = Object();

class FavoritesState {
  final List<FavoriteItemModel> favorites;
  final int? updatingItemId;
  final String? errorMessage;

  const FavoritesState({
    required this.favorites,
    this.updatingItemId,
    this.errorMessage,
  });

  Set<int> get favoriteItemIds {
    return favorites.map((item) => item.itemId).toSet();
  }

  bool isFavorite(int itemId) {
    return favoriteItemIds.contains(itemId);
  }

  FavoritesState copyWith({
    List<FavoriteItemModel>? favorites,
    Object? updatingItemId = _unset,
    Object? errorMessage = _unset,
  }) {
    return FavoritesState(
      favorites: favorites ?? this.favorites,
      updatingItemId: identical(updatingItemId, _unset)
          ? this.updatingItemId
          : updatingItemId as int?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

final favoritesControllerProvider =
    AsyncNotifierProvider<FavoritesController, FavoritesState>(
      FavoritesController.new,
    );

class FavoritesController extends AsyncNotifier<FavoritesState> {
  FavoriteRepository get _repository => ref.read(favoriteRepositoryProvider);

  @override
  FutureOr<FavoritesState> build() async {
    final favorites = await _repository.fetchMyFavorites();

    return FavoritesState(favorites: favorites);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final favorites = await _repository.fetchMyFavorites();

      return FavoritesState(favorites: favorites);
    });
  }

  Future<bool> toggleFavorite(int itemId) async {
    if (itemId == 0) return false;

    var current = state.value;

    if (current == null) {
      state = await AsyncValue.guard(() async {
        final favorites = await _repository.fetchMyFavorites();

        return FavoritesState(favorites: favorites);
      });

      current = state.value;
    }

    if (current == null) return false;

    final alreadyFavorite = current.isFavorite(itemId);

    state = AsyncData(
      current.copyWith(updatingItemId: itemId, errorMessage: null),
    );

    try {
      if (alreadyFavorite) {
        await _repository.removeFavorite(itemId);

        final updated = current.favorites
            .where((favorite) => favorite.itemId != itemId)
            .toList();

        state = AsyncData(
          current.copyWith(
            favorites: updated,
            updatingItemId: null,
            errorMessage: null,
          ),
        );
      } else {
        await _repository.addFavorite(itemId);

        final latestFavorites = await _repository.fetchMyFavorites();

        state = AsyncData(
          current.copyWith(
            favorites: latestFavorites,
            updatingItemId: null,
            errorMessage: null,
          ),
        );
      }

      return true;
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          updatingItemId: null,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      return false;
    }
  }
}
