import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/category_model.dart';
import '../models/item_model.dart';
import '../models/review_model.dart';

class ItemRepository {
  final Dio _dio;

  const ItemRepository({required Dio dio}) : _dio = dio;

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _dio.get(ApiConstants.categories);

      return _parseListResponse<CategoryModel>(
        response.data,
        CategoryModel.fromJson,
        invalidMessage: 'Format data kategori tidak valid.',
      );
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<List<ItemModel>> fetchItems({
    String? search,
    int? categoryId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'page': page, 'limit': limit};

      final cleanSearch = search?.trim();

      if (cleanSearch != null && cleanSearch.isNotEmpty) {
        queryParameters['search'] = cleanSearch;
      }

      if (categoryId != null) {
        queryParameters['category_id'] = categoryId;
      }

      if (status != null && status.trim().isNotEmpty) {
        queryParameters['status'] = status;
      }

      final response = await _dio.get(
        ApiConstants.items,
        queryParameters: queryParameters,
      );

      return _parseListResponse<ItemModel>(
        response.data,
        ItemModel.fromJson,
        invalidMessage: 'Format data barang tidak valid.',
      );
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<ItemModel> fetchItemDetail(int itemId) async {
    try {
      final response = await _dio.get(ApiConstants.itemDetail(itemId));
      final body = response.data;

      if (body is Map<String, dynamic>) {
        final data = body['data'];

        if (data is Map<String, dynamic>) {
          return ItemModel.fromJson(data);
        }

        if (body.containsKey('id')) {
          return ItemModel.fromJson(body);
        }
      }

      throw const ApiException(message: 'Format detail barang tidak valid.');
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<List<ReviewModel>> fetchItemReviews(int itemId) async {
    try {
      final response = await _dio.get(ApiConstants.itemReviews(itemId));

      return _parseListResponse<ReviewModel>(
        response.data,
        ReviewModel.fromJson,
        invalidMessage: 'Format data review tidak valid.',
      );
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  List<T> _parseListResponse<T>(
    Object? body,
    T Function(Map<String, dynamic> json) fromJson, {
    required String invalidMessage,
  }) {
    Object? data = body;

    if (body is Map<String, dynamic>) {
      data = body['data'];
    }

    if (data is! List) {
      throw ApiException(message: invalidMessage);
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map<T>((json) => fromJson(json))
        .toList();
  }

  ApiException _handleDioError(DioException error) {
    final err = error.error;

    if (err is ApiException) {
      return err;
    }

    return ApiException.fromDio(error);
  }
}
