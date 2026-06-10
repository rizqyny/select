import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/category_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/admin_category_repository.dart';

const Object _unset = Object();

class AdminCategoriesState {
  final List<CategoryModel> categories;
  final int? updatingId;
  final String? errorMessage;

  const AdminCategoriesState({
    required this.categories,
    this.updatingId,
    this.errorMessage,
  });

  AdminCategoriesState copyWith({
    List<CategoryModel>? categories,
    Object? updatingId = _unset,
    Object? errorMessage = _unset,
  }) {
    return AdminCategoriesState(
      categories: categories ?? this.categories,
      updatingId: identical(updatingId, _unset)
          ? this.updatingId
          : updatingId as int?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

final adminCategoriesControllerProvider =
    AsyncNotifierProvider<AdminCategoriesController, AdminCategoriesState>(
      AdminCategoriesController.new,
    );

class AdminCategoriesController extends AsyncNotifier<AdminCategoriesState> {
  AdminCategoryRepository get _repository =>
      ref.read(adminCategoryRepositoryProvider);

  @override
  FutureOr<AdminCategoriesState> build() async {
    final categories = await _repository.fetchCategories();

    return AdminCategoriesState(categories: categories);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final categories = await _repository.fetchCategories();

      return AdminCategoriesState(categories: categories);
    });
  }

  Future<bool> create({
    required String name,
    required String description,
  }) async {
    final current = state.value;

    if (current == null) return false;

    state = AsyncData(current.copyWith(updatingId: -1, errorMessage: null));

    try {
      await _repository.createCategory(name: name, description: description);

      await refresh();
      return true;
    } catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          updatingId: null,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      return false;
    }
  }

  Future<bool> updateCategory({
    required int id,
    required String name,
    required String description,
  }) async {
    final current = state.value;

    if (current == null) return false;

    state = AsyncData(current.copyWith(updatingId: id, errorMessage: null));

    try {
      await _repository.updateCategory(
        id: id,
        name: name,
        description: description,
      );

      await refresh();
      return true;
    } catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          updatingId: null,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      return false;
    }
  }

  Future<bool> delete(int id) async {
    final current = state.value;

    if (current == null) return false;

    state = AsyncData(current.copyWith(updatingId: id, errorMessage: null));

    try {
      await _repository.deleteCategory(id);
      await refresh();
      return true;
    } catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          updatingId: null,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      return false;
    }
  }
}
