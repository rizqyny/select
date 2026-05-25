import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({
    required this.message,
    this.statusCode,
  });

  factory ApiException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      return ApiException(
        message: data['message']?.toString() ?? 'Terjadi kesalahan pada server',
        statusCode: statusCode,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiException(
        message: 'Koneksi timeout. Periksa internet kamu.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return const ApiException(
        message: 'Tidak dapat terhubung ke server.',
      );
    }

    return ApiException(
      message: error.message ?? 'Terjadi kesalahan tidak diketahui',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => message;
}