import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';

class FavoriteRepository {
  final Dio _dio;

  const FavoriteRepository({required Dio dio}) : _dio = dio;

  Future<List<int>> fetchMyFavoriteItemIds() async {
    try {
      final response = await _dio.get(ApiConstants.myFavorites);
      final body = response.data;

      Object? data = body;

      if (body is Map<String, dynamic>) {
        data = body['data'];
      }

      if (data is! List) {
        return <int>[];
      }

      final ids = <int>[];

      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;

        final directItemId = _toIntNullable(item['item_id']);
        if (directItemId != null) {
          ids.add(directItemId);
          continue;
        }

        final nestedItem = item['item'];
        if (nestedItem is Map<String, dynamic>) {
          final nestedItemId = _toIntNullable(nestedItem['id']);
          if (nestedItemId != null) {
            ids.add(nestedItemId);
            continue;
          }
        }

        final nestedItems = item['items'];
        if (nestedItems is Map<String, dynamic>) {
          final nestedItemId = _toIntNullable(nestedItems['id']);
          if (nestedItemId != null) {
            ids.add(nestedItemId);
            continue;
          }
        }

        final directId = _toIntNullable(item['id']);
        final hasItemShape =
            item.containsKey('name') ||
            item.containsKey('daily_price') ||
            item.containsKey('category_id');

        if (directId != null && hasItemShape) {
          ids.add(directId);
        }
      }

      return ids.toSet().toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> addFavorite(int itemId) async {
    try {
      await _dio.post(ApiConstants.favoriteByItem(itemId));
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> removeFavorite(int itemId) async {
    try {
      await _dio.delete(ApiConstants.favoriteByItem(itemId));
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  int? _toIntNullable(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  ApiException _handleDioError(DioException error) {
    final err = error.error;

    if (err is ApiException) {
      return err;
    }

    return ApiException.fromDio(error);
  }
}
