import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/admin_user_model.dart';

class AdminUserRepository {
  final Dio _dio;

  const AdminUserRepository({required Dio dio}) : _dio = dio;

  Future<List<AdminUserModel>> fetchAdminUsers() async {
    try {
      final response = await _dio.get(ApiConstants.adminUsers);

      final rawList = _extractList(response.data);

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(AdminUserModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<AdminUserModel> updateUserRole({
    required int id,
    required String role,
  }) async {
    try {
      final response = await _dio.patch(
        ApiConstants.adminUpdateUserRole(id),
        data: {'role': role},
      );

      return _extractUser(response.data);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  AdminUserModel _extractUser(Object? body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];

      if (data is Map<String, dynamic>) {
        return AdminUserModel.fromJson(data);
      }

      if (body.containsKey('id')) {
        return AdminUserModel.fromJson(body);
      }
    }

    throw const ApiException(message: 'Format response user tidak valid.');
  }

  List<dynamic> _extractList(Object? body) {
    Object? data = body;

    if (body is Map<String, dynamic>) {
      data = body['data'];

      if (data is Map<String, dynamic>) {
        final nestedData =
            data['items'] ?? data['data'] ?? data['results'] ?? data['rows'];

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
