import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final Dio _dio;

  const ReviewRepository({required Dio dio}) : _dio = dio;

  Future<ReviewModel> createReview({
    required int bookingId,
    required int itemId,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.createReview(bookingId: bookingId, itemId: itemId),
        data: {'rating': rating, 'comment': comment.trim()},
      );

      return _extractReview(response.data);
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<List<ReviewModel>> fetchMyReviews() async {
    try {
      final response = await _dio.get(ApiConstants.myReviews);

      final rawList = _extractList(response.data);

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(ReviewModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<List<ReviewModel>> fetchItemReviews(int itemId) async {
    try {
      final response = await _dio.get(ApiConstants.itemReviews(itemId));

      final rawList = _extractList(response.data);

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(ReviewModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  ReviewModel _extractReview(Object? body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];

      if (data is Map<String, dynamic>) {
        return ReviewModel.fromJson(data);
      }

      if (body.containsKey('id')) {
        return ReviewModel.fromJson(body);
      }
    }

    throw const ApiException(message: 'Format response review tidak valid.');
  }

  List<dynamic> _extractList(Object? body) {
    Object? data = body;

    if (body is Map<String, dynamic>) {
      data = body['data'];

      if (data is Map<String, dynamic>) {
        final nested =
            data['items'] ?? data['data'] ?? data['rows'] ?? data['results'];

        if (nested is List) return nested;

        return <dynamic>[];
      }
    }

    if (data is List) return data;

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
