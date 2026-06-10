import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/admin_identity_verification_model.dart';

class AdminVerificationRepository {
  final Dio _dio;

  const AdminVerificationRepository({required Dio dio}) : _dio = dio;

  Future<List<AdminIdentityVerificationModel>> fetchIdentityVerifications({
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
        ApiConstants.adminIdentityVerifications,
        queryParameters: queryParameters,
      );

      final rawList = _extractList(response.data);

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(AdminIdentityVerificationModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> approveIdentityVerification(int id) async {
    try {
      await _patchOrPost(ApiConstants.adminApproveIdentityVerification(id));
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> rejectIdentityVerification({
    required int id,
    required String reason,
  }) async {
    final endpoint = ApiConstants.adminRejectIdentityVerification(id);
    final cleanReason = reason.trim();

    final payloads = cleanReason.isEmpty
        ? <Map<String, dynamic>>[<String, dynamic>{}]
        : <Map<String, dynamic>>[
            {'reason': cleanReason},
            {'rejection_reason': cleanReason},
            {'admin_note': cleanReason},
            {'note': cleanReason},
          ];

    DioException? lastError;

    for (final payload in payloads) {
      try {
        await _patchOrPost(endpoint, data: payload);
        return;
      } on DioException catch (error) {
        lastError = error;

        final statusCode = error.response?.statusCode;

        if (statusCode != 400 && statusCode != 422) {
          rethrow;
        }
      }
    }

    if (lastError != null) {
      throw _handleDioError(lastError);
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
            data['verifications'];

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
