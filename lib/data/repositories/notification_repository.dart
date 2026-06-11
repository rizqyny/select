import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final Dio _dio;

  const NotificationRepository({required Dio dio}) : _dio = dio;

  Future<List<NotificationModel>> fetchMyNotifications({
    bool? isRead,
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.myNotifications,
        queryParameters: {
          'is_read': ?isRead,
          'page': page,
          'limit': limit,
        },
      );

      final rawList = _extractList(response.data);

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _dio.patch(ApiConstants.readNotification(id));
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.patch(ApiConstants.readAllNotifications);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> sendTestNotification() async {
    try {
      await _dio.post(
        ApiConstants.testNotification,
        data: {
          'title': 'Tes Notifikasi SELECT',
          'body': 'Ini adalah notifikasi percobaan dari aplikasi SELECT.',
          'data': {'screen': 'notifications'},
        },
      );
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> registerDeviceToken({
    required String fcmToken,
    required String platform,
    required String deviceName,
  }) async {
    try {
      await _dio.post(
        ApiConstants.registerDeviceToken,
        data: {
          'fcm_token': fcmToken,
          'platform': platform,
          'device_name': deviceName,
        },
      );
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  List<dynamic> _extractList(Object? body) {
    Object? data = body;

    if (body is Map<String, dynamic>) {
      data = body['data'];

      if (data is Map<String, dynamic>) {
        final nested =
            data['items'] ?? data['data'] ?? data['rows'] ?? data['results'];

        if (nested is List) return nested;

        return <dynamic>[];
      }
    }

    if (data is List) return data;

    return <dynamic>[];
  }

  ApiException _handleDioError(DioException error) {
    final err = error.error;

    if (err is ApiException) {
      return err;
    }

    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      return ApiException(
        message:
            data['message']?.toString() ??
            data['error']?.toString() ??
            data.toString(),
        statusCode: error.response?.statusCode,
      );
    }

    return ApiException.fromDio(error);
  }
}
