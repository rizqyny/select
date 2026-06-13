import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/item_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/favorite_repository.dart';
import '../../../../data/repositories/item_repository.dart';

const Object _unset = Object();

final customerHomeControllerProvider =
    AsyncNotifierProvider<CustomerHomeController, CustomerHomeState>(
      CustomerHomeController.new,
    );

class CustomerHomeState {
  final List<CategoryModel> categories;
  final List<ItemModel> items;
  final int? selectedCategoryId;
  final String searchQuery;
  final bool isLoadingItems;
  final String? errorMessage;
  final Set<int> favoriteItemIds;

  const CustomerHomeState({
    required this.categories,
    required this.items,
    required this.selectedCategoryId,
    required this.searchQuery,
    required this.isLoadingItems,
    required this.errorMessage,
    required this.favoriteItemIds,
  });

  CustomerHomeState copyWith({
    List<CategoryModel>? categories,
    List<ItemModel>? items,
    Object? selectedCategoryId = _unset,
    String? searchQuery,
    bool? isLoadingItems,
    Object? errorMessage = _unset,
    Set<int>? favoriteItemIds,
  }) {
    return CustomerHomeState(
      categories: categories ?? this.categories,
      items: items ?? this.items,
      selectedCategoryId: identical(selectedCategoryId, _unset)
          ? this.selectedCategoryId
          : selectedCategoryId as int?,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingItems: isLoadingItems ?? this.isLoadingItems,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      favoriteItemIds: favoriteItemIds ?? this.favoriteItemIds,
    );
  }
}

class CustomerHomeController extends AsyncNotifier<CustomerHomeState> {
  ItemRepository get _itemRepository => ref.read(itemRepositoryProvider);

  FavoriteRepository get _favoriteRepository =>
      ref.read(favoriteRepositoryProvider);

  @override
  FutureOr<CustomerHomeState> build() async {
    final categories = await _itemRepository.fetchCategories();
    final items = await _itemRepository.fetchItems();
    final favoriteIds = await _favoriteRepository.fetchMyFavoriteItemIds();

    return CustomerHomeState(
      categories: categories,
      items: items,
      selectedCategoryId: null,
      searchQuery: '',
      isLoadingItems: false,
      errorMessage: null,
      favoriteItemIds: favoriteIds,
    );
  }

  Future<void> refresh() async {
    final current = state.value;

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final categories = await _itemRepository.fetchCategories();
      final items = await _itemRepository.fetchItems(
        search: current?.searchQuery ?? '',
        categoryId: current?.selectedCategoryId,
      );
      final favoriteIds = await _favoriteRepository.fetchMyFavoriteItemIds();

      return CustomerHomeState(
        categories: categories,
        items: items,
        selectedCategoryId: current?.selectedCategoryId,
        searchQuery: current?.searchQuery ?? '',
        isLoadingItems: false,
        errorMessage: null,
        favoriteItemIds: favoriteIds,
      );
    });
  }

  Future<void> setCategory(int? categoryId) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        selectedCategoryId: categoryId,
        isLoadingItems: true,
        errorMessage: null,
      ),
    );

    try {
      final items = await _itemRepository.fetchItems(
        search: current.searchQuery,
        categoryId: categoryId,
      );

      final favoriteIds = await _favoriteRepository.fetchMyFavoriteItemIds();

      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          selectedCategoryId: categoryId,
          items: items,
          isLoadingItems: false,
          errorMessage: null,
          favoriteItemIds: favoriteIds,
        ),
      );
    } catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          isLoadingItems: false,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> setSearch(String query) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        searchQuery: query,
        isLoadingItems: true,
        errorMessage: null,
      ),
    );

    try {
      final items = await _itemRepository.fetchItems(
        search: query,
        categoryId: current.selectedCategoryId,
      );

      final favoriteIds = await _favoriteRepository.fetchMyFavoriteItemIds();

      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          searchQuery: query,
          items: items,
          isLoadingItems: false,
          errorMessage: null,
          favoriteItemIds: favoriteIds,
        ),
      );
    } catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          isLoadingItems: false,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> toggleFavorite(ItemModel item) async {
    final current = state.value;
    if (current == null) return;

    final favoriteIds = <int>{...current.favoriteItemIds};
    final alreadyFavorite = favoriteIds.contains(item.id);

    if (alreadyFavorite) {
      favoriteIds.remove(item.id);
    } else {
      favoriteIds.add(item.id);
    }

    state = AsyncData(
      current.copyWith(favoriteItemIds: favoriteIds, errorMessage: null),
    );

    try {
      if (alreadyFavorite) {
        await _favoriteRepository.removeFavorite(item.id);
      } else {
        await _favoriteRepository.addFavorite(item.id);
      }

      final latestFavoriteIds = await _favoriteRepository
          .fetchMyFavoriteItemIds();

      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(favoriteItemIds: latestFavoriteIds, errorMessage: null),
      );
    } catch (error) {
      if (alreadyFavorite && _isFavoriteAlreadyRemoved(error)) {
        final latest = state.value ?? current;

        state = AsyncData(
          latest.copyWith(favoriteItemIds: favoriteIds, errorMessage: null),
        );
        return;
      }

      state = AsyncData(
        current.copyWith(
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  bool _isFavoriteAlreadyRemoved(Object error) {
    if (error is ApiException && error.statusCode == 404) {
      return true;
    }

    final message = error.toString().toLowerCase();

    return message.contains('tidak ada') ||
        message.contains('not found') ||
        message.contains('favorite');
  }
}
