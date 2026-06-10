import 'dart:io';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        throw Exception('Signed upload URL kosong dari server.');
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
    } catch (error) {
      // Fallback jika backend /storage/signed-upload-url error 500.
      // File tetap diupload langsung ke Supabase Storage.
      return _uploadDirectlyToSupabase(
        file: file,
        bucket: bucket,
        path: path,
        contentType: contentType,
      );
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

      throw Exception('Format signed upload URL tidak valid.');
    } on DioException catch (error) {
      throw Exception(
        'Gagal membuat signed upload URL: ${_extractErrorMessage(error)}',
      );
    } catch (error) {
      throw Exception('Gagal membuat signed upload URL: $error');
    }
  }

  Future<String> _uploadDirectlyToSupabase({
    required File file,
    required String bucket,
    required String path,
    required String contentType,
  }) async {
    try {
      await Supabase.instance.client.storage
          .from(bucket)
          .upload(
            path,
            file,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );

      return path;
    } on StorageException catch (error) {
      throw Exception('Gagal upload foto KTP ke Supabase: ${error.message}');
    } catch (error) {
      throw Exception('Gagal upload foto KTP ke Supabase: $error');
    }
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          data.toString();
    }

    if (data != null) {
      return data.toString();
    }

    final err = error.error;

    if (err is ApiException) {
      return err.message;
    }

    return error.message ?? 'Terjadi kesalahan koneksi.';
  }
}
