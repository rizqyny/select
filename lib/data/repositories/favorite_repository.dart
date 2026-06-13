import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/favorite_model.dart';

class FavoriteRepository {
  final Dio _dio;

  const FavoriteRepository({required Dio dio}) : _dio = dio;

  Future<List<FavoriteItemModel>> fetchMyFavorites() async {
    try {
      final response = await _dio.get(ApiConstants.myFavorites);
      final list = _extractList(response.data);

      return list
          .whereType<Map<String, dynamic>>()
          .map(FavoriteItemModel.fromJson)
          .where((item) => item.itemId != 0)
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<Set<int>> fetchMyFavoriteItemIds() async {
    final favorites = await fetchMyFavorites();
    return favorites.map((item) => item.itemId).toSet();
  }

  Future<void> addFavorite(int itemId) async {
    try {
      await _dio.post(ApiConstants.favoriteByItem(itemId));
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final message = _extractErrorMessage(error).toLowerCase();

      if (statusCode == 409 ||
          message.contains('sudah') ||
          message.contains('already')) {
        return;
      }

      throw _handleDioError(error);
    }
  }

  Future<void> removeFavorite(int itemId) async {
    try {
      await _dio.delete(ApiConstants.favoriteByItem(itemId));
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final message = _extractErrorMessage(error).toLowerCase();

      // Kalau dari home masih dianggap favorit, tapi backend sudah tidak punya data favorit,
      // anggap sukses supaya icon love bisa ikut hilang dan tidak muncul snackbar error.
      if (statusCode == 404 ||
          message.contains('tidak ada') ||
          message.contains('not found')) {
        return;
      }

      throw _handleDioError(error);
    }
  }

  List<dynamic> _extractList(Object? body) {
    if (body is List) return body;

    if (body is Map<String, dynamic>) {
      final data = body['data'];

      if (data is List) return data;

      if (data is Map<String, dynamic>) {
        final nested =
            data['favorites'] ??
            data['items'] ??
            data['data'] ??
            data['rows'] ??
            data['results'];

        if (nested is List) return nested;
      }
    }

    return <dynamic>[];
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          data.toString();
    }

    return error.message ?? 'Terjadi kesalahan koneksi.';
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
