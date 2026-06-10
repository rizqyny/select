import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/category_model.dart';

class AdminCategoryRepository {
  final Dio _dio;

  const AdminCategoryRepository({required Dio dio}) : _dio = dio;

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _dio.get(ApiConstants.adminCategories);

      final rawList = _extractList(response.data);

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<CategoryModel> createCategory({
    required String name,
    required String description,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.adminCreateCategory,
        data: {
          'name': name.trim(),
          if (description.trim().isNotEmpty) 'description': description.trim(),
        },
      );

      return _extractCategory(response.data);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<CategoryModel> updateCategory({
    required int id,
    required String name,
    required String description,
  }) async {
    try {
      final response = await _dio.patch(
        ApiConstants.adminUpdateCategory(id),
        data: {
          'name': name.trim(),
          if (description.trim().isNotEmpty) 'description': description.trim(),
        },
      );

      return _extractCategory(response.data);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _dio.delete(ApiConstants.adminDeleteCategory(id));
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  CategoryModel _extractCategory(Object? body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];

      if (data is Map<String, dynamic>) {
        return CategoryModel.fromJson(data);
      }

      if (body.containsKey('id')) {
        return CategoryModel.fromJson(body);
      }
    }

    throw const ApiException(message: 'Format response kategori tidak valid.');
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
