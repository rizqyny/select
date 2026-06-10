import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/models/admin_item_model.dart';
import '../../../../../data/providers/repository_providers.dart';
import '../../../../../data/repositories/admin_item_repository.dart';

const Object _unset = Object();

class AdminItemsState {
  final List<AdminItemModel> items;
  final String search;
  final String? selectedStatus;
  final int? deletingId;
  final String? errorMessage;

  const AdminItemsState({
    required this.items,
    this.search = '',
    this.selectedStatus,
    this.deletingId,
    this.errorMessage,
  });

  AdminItemsState copyWith({
    List<AdminItemModel>? items,
    String? search,
    Object? selectedStatus = _unset,
    Object? deletingId = _unset,
    Object? errorMessage = _unset,
  }) {
    return AdminItemsState(
      items: items ?? this.items,
      search: search ?? this.search,
      selectedStatus: identical(selectedStatus, _unset)
          ? this.selectedStatus
          : selectedStatus as String?,
      deletingId: identical(deletingId, _unset)
          ? this.deletingId
          : deletingId as int?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

final adminItemsControllerProvider =
    AsyncNotifierProvider<AdminItemsController, AdminItemsState>(
      AdminItemsController.new,
    );

class AdminItemsController extends AsyncNotifier<AdminItemsState> {
  AdminItemRepository get _repository => ref.read(adminItemRepositoryProvider);

  @override
  FutureOr<AdminItemsState> build() async {
    final items = await _repository.fetchAdminItems();

    return AdminItemsState(items: items);
  }

  Future<void> refresh() async {
    final current = state.value;

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final items = await _repository.fetchAdminItems(
        search: current?.search,
        status: current?.selectedStatus,
      );

      return AdminItemsState(
        items: items,
        search: current?.search ?? '',
        selectedStatus: current?.selectedStatus,
      );
    });
  }

  Future<void> search(String value) async {
    final current = state.value;

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final items = await _repository.fetchAdminItems(
        search: value,
        status: current?.selectedStatus,
      );

      return AdminItemsState(
        items: items,
        search: value,
        selectedStatus: current?.selectedStatus,
      );
    });
  }

  Future<void> setStatus(String? status) async {
    final current = state.value;

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final items = await _repository.fetchAdminItems(
        search: current?.search,
        status: status,
      );

      return AdminItemsState(
        items: items,
        search: current?.search ?? '',
        selectedStatus: status,
      );
    });
  }

  Future<bool> deleteItem(int id) async {
    final current = state.value;

    if (current == null) return false;

    state = AsyncData(current.copyWith(deletingId: id, errorMessage: null));

    try {
      await _repository.deleteItem(id);
      await refresh();
      return true;
    } catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          deletingId: null,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      return false;
    }
  }
}
