import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/admin_booking_model.dart';

class AdminBookingRepository {
  final Dio _dio;

  const AdminBookingRepository({required Dio dio}) : _dio = dio;

  Future<List<AdminBookingModel>> fetchAdminBookings({
    String? status,
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'page': page, 'limit': limit};

      if (status != null && status.trim().isNotEmpty) {
        queryParameters['status'] = status;
      }

      final response = await _dio.get(
        ApiConstants.adminBookings,
        queryParameters: queryParameters,
      );

      final rawList = _extractList(response.data);

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(AdminBookingModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> approveBooking(int id) async {
    try {
      await _patchOrPost(ApiConstants.adminApproveBooking(id));
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> rejectBooking({required int id, required String reason}) async {
    try {
      await _patchOrPost(
        ApiConstants.adminRejectBooking(id),
        data: {if (reason.trim().isNotEmpty) 'reason': reason.trim()},
      );
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> startBooking(int id) async {
    try {
      await _patchOrPost(ApiConstants.adminStartBooking(id));
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> completeBooking(int id) async {
    try {
      await _patchOrPost(ApiConstants.adminCompleteBooking(id));
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<Response<dynamic>> _patchOrPost(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _dio.patch(endpoint, data: data);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;

      if (statusCode == 404 || statusCode == 405) {
        return _dio.post(endpoint, data: data);
      }

      rethrow;
    }
  }

  List<dynamic> _extractList(Object? body) {
    Object? data = body;

    if (body is Map<String, dynamic>) {
      data = body['data'];

      if (data is Map<String, dynamic>) {
        final nestedData =
            data['items'] ??
            data['data'] ??
            data['results'] ??
            data['rows'] ??
            data['bookings'];

        if (nestedData is List) {
          return nestedData;
        }

        return <dynamic>[];
      }
    }

    if (data is List) {
      return data;
    }

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
