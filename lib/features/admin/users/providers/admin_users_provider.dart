import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/admin_user_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/admin_user_repository.dart';

const Object _unset = Object();

class AdminUsersState {
  final List<AdminUserModel> users;
  final int? updatingId;
  final String? errorMessage;

  const AdminUsersState({
    required this.users,
    this.updatingId,
    this.errorMessage,
  });

  AdminUsersState copyWith({
    List<AdminUserModel>? users,
    Object? updatingId = _unset,
    Object? errorMessage = _unset,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      updatingId: identical(updatingId, _unset)
          ? this.updatingId
          : updatingId as int?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

final adminUsersControllerProvider =
    AsyncNotifierProvider<AdminUsersController, AdminUsersState>(
      AdminUsersController.new,
    );

class AdminUsersController extends AsyncNotifier<AdminUsersState> {
  AdminUserRepository get _repository => ref.read(adminUserRepositoryProvider);

  @override
  FutureOr<AdminUsersState> build() async {
    final users = await _repository.fetchAdminUsers();

    return AdminUsersState(users: users);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final users = await _repository.fetchAdminUsers();

      return AdminUsersState(users: users);
    });
  }

  Future<bool> changeRole({required int id, required String role}) async {
    final current = state.value;

    if (current == null) return false;

    state = AsyncData(current.copyWith(updatingId: id, errorMessage: null));

    try {
      await _repository.updateUserRole(id: id, role: role);

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
