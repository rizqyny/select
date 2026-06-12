import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/fcm_service.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/notification_repository.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});

final deviceTokenControllerProvider =
    AsyncNotifierProvider<DeviceTokenController, bool>(
      DeviceTokenController.new,
    );

class DeviceTokenController extends AsyncNotifier<bool> {
  FcmService get _fcmService => ref.read(fcmServiceProvider);

  NotificationRepository get _notificationRepository =>
      ref.read(notificationRepositoryProvider);

  @override
  FutureOr<bool> build() {
    return false;
  }

  Future<void> registerDevice() async {
    try {
      final token = await _fcmService.getToken();

      if (token == null || token.trim().isEmpty) {
        state = const AsyncData(false);
        return;
      }

      await _notificationRepository.registerDeviceToken(
        fcmToken: token,
        platform: _fcmService.platform,
        deviceName: _fcmService.deviceName,
      );

      state = const AsyncData(true);

      _listenTokenRefresh();
    } catch (_) {
      state = const AsyncData(false);
    }
  }

  void _listenTokenRefresh() {
    _fcmService.onTokenRefresh.listen((newToken) async {
      try {
        await _notificationRepository.registerDeviceToken(
          fcmToken: newToken,
          platform: _fcmService.platform,
          deviceName: _fcmService.deviceName,
        );
      } catch (_) {}
    });
  }
}
