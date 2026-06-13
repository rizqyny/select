import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final Dio _dio;

  const PaymentRepository({required Dio dio}) : _dio = dio;

  Future<PaymentModel> createPayment(int bookingId) async {
    try {
      final response = await _dio.post(ApiConstants.createPayment(bookingId));
      return _parsePayment(response.data);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<PaymentModel?> fetchPaymentByBooking(int bookingId) async {
    try {
      final response = await _dio.get(ApiConstants.paymentByBooking(bookingId));
      return _parsePayment(response.data);
    } on DioException {
      return null;
    }
  }

  Future<PaymentModel> simulatePaymentPaidByBooking(int bookingId) async {
    try {
      final response = await _dio.post(
        ApiConstants.simulatePaymentPaidByBooking(bookingId),
      );

      return _parsePayment(response.data);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  PaymentModel _parsePayment(Object? body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];

      if (data is Map<String, dynamic>) {
        return PaymentModel.fromJson(data);
      }

      if (body.containsKey('id')) {
        return PaymentModel.fromJson(body);
      }
    }

    throw const ApiException(
      message: 'Format response pembayaran tidak valid.',
    );
  }

  ApiException _handleDioError(DioException error) {
    final err = error.error;

    if (err is ApiException) {
      return err;
    }

    return ApiException.fromDio(error);
  }
}
