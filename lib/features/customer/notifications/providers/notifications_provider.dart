import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/notification_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/notification_repository.dart';

const Object _unset = Object();

class NotificationsState {
  final List<NotificationModel> notifications;
  final int? updatingId;
  final bool isMarkingAll;
  final String? errorMessage;

  const NotificationsState({
    required this.notifications,
    this.updatingId,
    this.isMarkingAll = false,
    this.errorMessage,
  });

  int get unreadCount {
    return notifications.where((notification) => !notification.isRead).length;
  }

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    Object? updatingId = _unset,
    bool? isMarkingAll,
    Object? errorMessage = _unset,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      updatingId: identical(updatingId, _unset)
          ? this.updatingId
          : updatingId as int?,
      isMarkingAll: isMarkingAll ?? this.isMarkingAll,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );

class NotificationsController extends AsyncNotifier<NotificationsState> {
  NotificationRepository get _repository =>
      ref.read(notificationRepositoryProvider);

  @override
  FutureOr<NotificationsState> build() async {
    final notifications = await _repository.fetchMyNotifications();

    return NotificationsState(notifications: notifications);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final notifications = await _repository.fetchMyNotifications();

      return NotificationsState(notifications: notifications);
    });
  }

  Future<bool> markAsRead(int id) async {
    final current = state.value;

    if (current == null) return false;

    state = AsyncData(current.copyWith(updatingId: id, errorMessage: null));

    try {
      await _repository.markAsRead(id);

      final updatedNotifications = current.notifications.map((notification) {
        if (notification.id == id) {
          return notification.copyWith(isRead: true);
        }

        return notification;
      }).toList();

      state = AsyncData(
        current.copyWith(
          notifications: updatedNotifications,
          updatingId: null,
          errorMessage: null,
        ),
      );

      return true;
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          updatingId: null,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    final current = state.value;

    if (current == null) return false;

    state = AsyncData(current.copyWith(isMarkingAll: true, errorMessage: null));

    try {
      await _repository.markAllAsRead();

      final updatedNotifications = current.notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();

      state = AsyncData(
        current.copyWith(
          notifications: updatedNotifications,
          isMarkingAll: false,
          errorMessage: null,
        ),
      );

      return true;
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isMarkingAll: false,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      return false;
    }
  }

  Future<bool> sendTestNotification() async {
    final current = state.value;

    if (current == null) return false;

    state = AsyncData(current.copyWith(errorMessage: null));

    try {
      await _repository.sendTestNotification();
      await refresh();

      return true;
    } catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      return false;
    }
  }
}
