import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/item_model.dart';
import '../../../../data/repositories/item_repository.dart';

const Object _unset = Object();

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(dio: ref.watch(dioProvider));
});

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

  const CustomerHomeState({
    required this.categories,
    required this.items,
    this.selectedCategoryId,
    this.searchQuery = '',
    this.isLoadingItems = false,
    this.errorMessage,
  });

  factory CustomerHomeState.initial() {
    return const CustomerHomeState(categories: [], items: []);
  }

  CustomerHomeState copyWith({
    List<CategoryModel>? categories,
    List<ItemModel>? items,
    Object? selectedCategoryId = _unset,
    String? searchQuery,
    bool? isLoadingItems,
    Object? errorMessage = _unset,
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
    );
  }
}

class CustomerHomeController extends AsyncNotifier<CustomerHomeState> {
  ItemRepository get _repository => ref.read(itemRepositoryProvider);

  @override
  FutureOr<CustomerHomeState> build() async {
    final categories = await _repository.fetchCategories();
    final items = await _repository.fetchItems();

    return CustomerHomeState(categories: categories, items: items);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    try {
      final categories = await _repository.fetchCategories();
      final current = state.value ?? CustomerHomeState.initial();

      final items = await _repository.fetchItems(
        search: current.searchQuery,
        categoryId: current.selectedCategoryId,
      );

      state = AsyncData(
        CustomerHomeState(
          categories: categories,
          items: items,
          selectedCategoryId: current.selectedCategoryId,
          searchQuery: current.searchQuery,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> setCategory(int? categoryId) async {
    final current = state.value ?? CustomerHomeState.initial();

    state = AsyncData(
      current.copyWith(
        selectedCategoryId: categoryId,
        isLoadingItems: true,
        errorMessage: null,
      ),
    );

    try {
      final items = await _repository.fetchItems(
        search: current.searchQuery,
        categoryId: categoryId,
      );

      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          items: items,
          selectedCategoryId: categoryId,
          isLoadingItems: false,
          errorMessage: null,
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
    final current = state.value ?? CustomerHomeState.initial();
    final cleanQuery = query.trim();

    state = AsyncData(
      current.copyWith(
        searchQuery: cleanQuery,
        isLoadingItems: true,
        errorMessage: null,
      ),
    );

    try {
      final items = await _repository.fetchItems(
        search: cleanQuery,
        categoryId: current.selectedCategoryId,
      );

      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          items: items,
          searchQuery: cleanQuery,
          isLoadingItems: false,
          errorMessage: null,
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
}
