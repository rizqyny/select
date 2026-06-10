import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/admin_item_model.dart';

class AdminItemRepository {
  final Dio _dio;

  const AdminItemRepository({required Dio dio}) : _dio = dio;

  Future<List<AdminItemModel>> fetchAdminItems({
    String? search,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'page': page, 'limit': limit};

      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      if (status != null && status.trim().isNotEmpty) {
        queryParameters['status'] = status.trim();
      }

      final response = await _dio.get(
        ApiConstants.adminItems,
        queryParameters: queryParameters,
      );

      final rawList = _extractList(response.data);

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(AdminItemModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _dio.delete(ApiConstants.adminDeleteItem(id));
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
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
