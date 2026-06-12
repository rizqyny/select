import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';

class RegisterRepository {
  final Dio _dio;

  const RegisterRepository({required Dio dio}) : _dio = dio;

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      await _dio.post(
        ApiConstants.register,
        data: {
          'full_name': fullName.trim(),
          'email': email.trim(),
          'password': password,
          'phone': phone.trim(),
        },
      );
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
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
