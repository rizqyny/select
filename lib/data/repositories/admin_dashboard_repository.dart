import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/admin_dashboard_model.dart';

class AdminDashboardRepository {
  final Dio _dio;

  const AdminDashboardRepository({required Dio dio}) : _dio = dio;

  Future<AdminDashboardModel> fetchDashboard() async {
    try {
      final response = await _dio.get(
        ApiConstants.adminDashboard,
        queryParameters: {'top_item_limit': 3, 'recent_booking_limit': 5},
      );

      return AdminDashboardModel.fromJson(_asMap(response.data));
    } on DioException catch (_) {
      return _fetchDashboardSeparately();
    }
  }

  Future<AdminDashboardModel> _fetchDashboardSeparately() async {
    try {
      final summaryResponse = await _dio.get(
        ApiConstants.adminDashboardSummary,
      );

      final topItemsResponse = await _dio.get(
        ApiConstants.adminDashboardTopItems,
        queryParameters: {'top_item_limit': 3},
      );

      final recentBookingsResponse = await _dio.get(
        ApiConstants.adminDashboardRecentBookings,
        queryParameters: {'recent_booking_limit': 5},
      );

      final statusResponse = await _dio.get(
        ApiConstants.adminDashboardBookingStatusDistribution,
      );

      final summaryData = _extractData(summaryResponse.data);
      final topItemsData = _extractData(topItemsResponse.data);
      final recentBookingsData = _extractData(recentBookingsResponse.data);
      final statusData = _extractData(statusResponse.data);

      return AdminDashboardModel.fromJson({
        'data': {
          'summary': summaryData,
          'top_items': topItemsData,
          'recent_bookings': recentBookingsData,
          'booking_status_distribution': statusData,
        },
      });
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Object? _extractData(Object? body) {
    if (body is Map<String, dynamic>) {
      return body['data'] ?? body;
    }

    return body;
  }

  Map<String, dynamic> _asMap(Object? body) {
    if (body is Map<String, dynamic>) {
      return body;
    }

    return <String, dynamic>{};
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
