import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/availability_result.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final Dio _dio;

  const BookingRepository({required Dio dio}) : _dio = dio;

  Future<AvailabilityResult> checkAvailability({
    required List<int> itemIds,
    required DateTime rentalStartDate,
    required DateTime rentalEndDate,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.checkAvailability,
        data: {
          'item_ids': itemIds,
          'rental_start_date': _formatDate(rentalStartDate),
          'rental_end_date': _formatDate(rentalEndDate),
        },
      );

      final body = response.data;

      if (body is Map<String, dynamic>) {
        return AvailabilityResult.fromJson(body);
      }

      throw const ApiException(
        message: 'Format response ketersediaan tidak valid.',
      );
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<BookingModel> createBooking({
    required List<int> itemIds,
    required DateTime rentalStartDate,
    required DateTime rentalEndDate,
    String? customerNote,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.createBooking,
        data: {
          'item_ids': itemIds,
          'rental_start_date': _formatDate(rentalStartDate),
          'rental_end_date': _formatDate(rentalEndDate),
          if (customerNote != null && customerNote.trim().isNotEmpty)
            'customer_note': customerNote.trim(),
        },
      );

      return _parseSingleBooking(response.data);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<List<BookingModel>> fetchMyBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'page': page, 'limit': limit};

      if (status != null && status.trim().isNotEmpty) {
        queryParameters['status'] = status;
      }

      final response = await _dio.get(
        ApiConstants.myBookings,
        queryParameters: queryParameters,
      );

      final body = response.data;

      Object? data = body;

      if (body is Map<String, dynamic>) {
        data = body['data'];
      }

      if (data is! List) {
        throw const ApiException(message: 'Format data booking tidak valid.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(BookingModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<BookingModel> fetchBookingDetail(int bookingId) async {
    try {
      final response = await _dio.get(ApiConstants.bookingDetail(bookingId));
      return _parseSingleBooking(response.data);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  BookingModel _parseSingleBooking(Object? body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];

      if (data is Map<String, dynamic>) {
        return BookingModel.fromJson(data);
      }

      if (body.containsKey('id')) {
        return BookingModel.fromJson(body);
      }
    }

    throw const ApiException(message: 'Format response booking tidak valid.');
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  ApiException _handleDioError(DioException error) {
    final err = error.error;

    if (err is ApiException) {
      return err;
    }

    return ApiException.fromDio(error);
  }
}
