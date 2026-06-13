import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/category_model.dart';
import '../../../../data/models/item_model.dart';
import '../../../../data/providers/repository_providers.dart';
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
    int? selectedCategoryId,
    String? searchQuery,
    bool? isLoadingItems,
    String? errorMessage,
    Set<int>? favoriteItemIds,
  }) {
    return CustomerHomeState(
      categories: categories ?? this.categories,
      items: items ?? this.items,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingItems: isLoadingItems ?? this.isLoadingItems,
      errorMessage: errorMessage,
      favoriteItemIds: favoriteItemIds ?? this.favoriteItemIds,
    );
  }
}

final customerHomeControllerProvider =
    AsyncNotifierProvider<CustomerHomeController, CustomerHomeState>(
      CustomerHomeController.new,
    );

class CustomerHomeController extends AsyncNotifier<CustomerHomeState> {
  ItemRepository get _itemRepository => ref.read(itemRepositoryProvider);
  CategoryRepository get _categoryRepository =>
      ref.read(categoryRepositoryProvider);
  FavoriteRepository get _favoriteRepository =>
      ref.read(favoriteRepositoryProvider);

  @override
  Future<CustomerHomeState> build() async {
    final categories = await _categoryRepository.fetchCategories();
    final items = await _itemRepository.fetchItems();
    final favoriteIds = await _favoriteRepository.fetchMyFavoriteItemIds();

    return CustomerHomeState(
      categories: categories,
      items: items,
      selectedCategoryId: null,
      searchQuery: '',
      isLoadingItems: false,
      errorMessage: null,
      favoriteItemIds: favoriteIds.toSet(),
    );
  }

  Future<void> refresh() async {
    final current = state.value;

    state = const AsyncLoading();

    try {
      final categories = await _categoryRepository.fetchCategories();
      final items = await _itemRepository.fetchItems(
        search: current?.searchQuery,
        categoryId: current?.selectedCategoryId,
      );
      final favoriteIds = await _favoriteRepository.fetchMyFavoriteItemIds();

      state = AsyncData(
        CustomerHomeState(
          categories: categories,
          items: items,
          selectedCategoryId: current?.selectedCategoryId,
          searchQuery: current?.searchQuery ?? '',
          isLoadingItems: false,
          errorMessage: null,
          favoriteItemIds: favoriteIds.toSet(),
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
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

      state = AsyncData(
        current.copyWith(
          selectedCategoryId: categoryId,
          items: items,
          isLoadingItems: false,
        ),
      );
    } catch (e) {
      state = AsyncData(
        current.copyWith(
          isLoadingItems: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
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

      state = AsyncData(
        current.copyWith(
          searchQuery: query,
          items: items,
          isLoadingItems: false,
        ),
      );
    } catch (e) {
      state = AsyncData(
        current.copyWith(
          isLoadingItems: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> toggleFavorite(ItemModel item) async {
    final current = state.value;
    if (current == null) return;

    final currentFavorites = <int>{...current.favoriteItemIds};
    final isFavorite = currentFavorites.contains(item.id);

    if (isFavorite) {
      currentFavorites.remove(item.id);
    } else {
      currentFavorites.add(item.id);
    }

    state = AsyncData(
      current.copyWith(favoriteItemIds: currentFavorites, errorMessage: null),
    );

    try {
      if (isFavorite) {
        await _favoriteRepository.removeFavorite(item.id);
      } else {
        await _favoriteRepository.addFavorite(item.id);
      }

      ref.invalidate(myFavoritesControllerProvider);
      ref.invalidate(itemDetailControllerProvider(item.id));
    } catch (e) {
      state = AsyncData(
        current.copyWith(
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
