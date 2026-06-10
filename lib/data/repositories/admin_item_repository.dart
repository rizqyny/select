import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/admin_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<AdminItemModel> createItem({
    required String name,
    required String brand,
    required String serialNumber,
    required int categoryId,
    required String description,
    required num dailyPrice,
    required String status,
    String? imagePath,
  }) async {
    return _sendItemPayload(
      endpoint: ApiConstants.adminCreateItem,
      method: 'POST',
      name: name,
      brand: brand,
      serialNumber: serialNumber,
      categoryId: categoryId,
      description: description,
      dailyPrice: dailyPrice,
      status: status,
      imagePath: imagePath,
    );
  }

  Future<AdminItemModel> updateItem({
    required int id,
    required String name,
    required String brand,
    required String serialNumber,
    required int categoryId,
    required String description,
    required num dailyPrice,
    required String status,
    String? imagePath,
  }) async {
    return _sendItemPayload(
      endpoint: ApiConstants.adminUpdateItem(id),
      method: 'PATCH',
      name: name,
      brand: brand,
      serialNumber: serialNumber,
      categoryId: categoryId,
      description: description,
      dailyPrice: dailyPrice,
      status: status,
      imagePath: imagePath,
    );
  }

  Future<void> deleteItem(int id) async {
    try {
      await _dio.delete(ApiConstants.adminDeleteItem(id));
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<AdminItemModel> _sendItemPayload({
    required String endpoint,
    required String method,
    required String name,
    required String brand,
    required String serialNumber,
    required int categoryId,
    required String description,
    required num dailyPrice,
    required String status,
    String? imagePath,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'brand': brand.trim(),
      'serial_number': serialNumber.trim(),
      'category_id': categoryId,
      'description': description.trim(),
      'daily_price': dailyPrice,
      'status': status,
    };

    try {
      final response = method == 'POST'
          ? await _dio.post(endpoint, data: payload)
          : await _dio.patch(endpoint, data: payload);

      final item = _extractItem(response.data);

      if (imagePath != null && imagePath.trim().isNotEmpty) {
        await _attachPrimaryImage(itemId: item.id, imagePath: imagePath);
      }

      return item;
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<void> _attachPrimaryImage({
    required int itemId,
    required String imagePath,
  }) async {
    final cleanPath = imagePath.trim();

    if (cleanPath.isEmpty) return;

    try {
      final supabase = Supabase.instance.client;

      await supabase.from('item_images').insert({
        'item_id': itemId,
        'storage_path': cleanPath,
        'is_primary': true,
      });
    } on PostgrestException catch (error) {
      throw Exception(
        'Gagal menyimpan gambar ke tabel item_images: ${error.message}',
      );
    } catch (error) {
      throw Exception('Gagal menyimpan gambar ke tabel item_images: $error');
    }
  }

  AdminItemModel _extractItem(Object? body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];

      if (data is Map<String, dynamic>) {
        return AdminItemModel.fromJson(data);
      }

      if (body.containsKey('id')) {
        return AdminItemModel.fromJson(body);
      }
    }

    throw const ApiException(message: 'Format response item tidak valid.');
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
