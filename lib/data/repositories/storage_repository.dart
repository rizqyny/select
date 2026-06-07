import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/signed_upload_url_model.dart';

class StorageRepository {
  final Dio _dio;

  const StorageRepository({required Dio dio}) : _dio = dio;

  Future<String> uploadPrivateFile({
    required File file,
    required String bucket,
    required String path,
    required String contentType,
  }) async {
    try {
      final signedUrl = await _createSignedUploadUrl(
        bucket: bucket,
        path: path,
        contentType: contentType,
      );

      if (signedUrl.signedUrl.trim().isEmpty) {
        throw const ApiException(
          message: 'Signed upload URL tidak ditemukan dari server.',
        );
      }

      final bytes = await file.readAsBytes();

      await Dio().put(
        signedUrl.signedUrl,
        data: bytes,
        options: Options(
          headers: {'Content-Type': contentType},
          responseType: ResponseType.plain,
        ),
      );

      return signedUrl.path;
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<SignedUploadUrlModel> _createSignedUploadUrl({
    required String bucket,
    required String path,
    required String contentType,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.signedUploadUrl,
        data: {
          'bucket': bucket,
          'path': path,
          'content_type': contentType,
          'upsert': false,
        },
      );

      final body = response.data;

      if (body is Map<String, dynamic>) {
        return SignedUploadUrlModel.fromJson(
          body,
          fallbackBucket: bucket,
          fallbackPath: path,
        );
      }

      throw const ApiException(
        message: 'Format signed upload URL tidak valid.',
      );
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  ApiException _handleDioError(DioException error) {
    final err = error.error;

    if (err is ApiException) {
      return err;
    }

    return ApiException.fromDio(error);
  }
}
