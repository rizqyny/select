import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/admin_condition_verification_model.dart';

class AdminConditionVerificationRepository {
  final Dio _dio;

  const AdminConditionVerificationRepository({required Dio dio}) : _dio = dio;

  Future<List<AdminConditionVerificationModel>>
  fetchConditionVerifications() async {
    try {
      final response = await _dio.get(ApiConstants.adminConditionVerifications);

      final rawList = _extractList(response.data);

      final verifications = rawList
          .whereType<Map<String, dynamic>>()
          .map(AdminConditionVerificationModel.fromJson)
          .where((item) => item.isBeforeRent)
          .toList();

      verifications.sort((a, b) {
        if (a.isPending && !b.isPending) return -1;
        if (!a.isPending && b.isPending) return 1;

        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return verifications;
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<AdminConditionVerificationModel> approveCondition(int id) async {
    try {
      final response = await _dio.patch(
        ApiConstants.adminApproveConditionVerification(id),
      );

      return _extractVerification(response.data);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<AdminConditionVerificationModel> rejectCondition({
    required int id,
    required String reason,
  }) async {
    try {
      final response = await _dio.patch(
        ApiConstants.adminRejectConditionVerification(id),
        data: {'reason': reason.trim()},
      );

      return _extractVerification(response.data);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> startBooking({
    required int bookingId,
    required String note,
  }) async {
    try {
      await _dio.patch(
        ApiConstants.adminStartBooking(bookingId),
        data: {
          'note': note.trim().isEmpty
              ? 'Foto kondisi awal barang sudah disetujui admin. Masa sewa dimulai.'
              : note.trim(),
        },
      );
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> approveConditionAndStartBooking({
    required int verificationId,
    required int bookingId,
  }) async {
    await approveCondition(verificationId);

    await startBooking(
      bookingId: bookingId,
      note:
          'Foto kondisi awal barang sudah disetujui admin. Masa sewa dimulai.',
    );
  }

  AdminConditionVerificationModel _extractVerification(Object? body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];

      if (data is Map<String, dynamic>) {
        return AdminConditionVerificationModel.fromJson(data);
      }

      if (body.containsKey('id')) {
        return AdminConditionVerificationModel.fromJson(body);
      }
    }

    throw const ApiException(
      message: 'Format response verifikasi kondisi tidak valid.',
    );
  }

  List<dynamic> _extractList(Object? body) {
    Object? data = body;

    if (body is Map<String, dynamic>) {
      data = body['data'];

      if (data is Map<String, dynamic>) {
        final nested =
            data['items'] ?? data['data'] ?? data['rows'] ?? data['results'];

        if (nested is List) {
          return nested;
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
