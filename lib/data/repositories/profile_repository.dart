import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  final Dio _dio;

  const ProfileRepository({required Dio dio}) : _dio = dio;

  Future<ProfileModel> fetchMyProfile() async {
    try {
      final response = await _dio.get(ApiConstants.myProfile);

      return ProfileModel.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Future<ProfileModel> updateMyProfile({
    required String fullName,
    required String phone,
    String? avatarPath,
  }) async {
    try {
      final response = await _dio.patch(
        ApiConstants.myProfile,
        data: {
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          if (avatarPath != null && avatarPath.trim().isNotEmpty)
            'avatar_path': avatarPath.trim(),
        },
      );

      return ProfileModel.fromJson(_extractMap(response.data));
    } on DioException catch (error) {
      throw _handleDioError(error);
    }
  }

  Map<String, dynamic> _extractMap(Object? body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];

      if (data is Map<String, dynamic>) {
        if (data['profile'] is Map<String, dynamic>) {
          return data['profile'] as Map<String, dynamic>;
        }

        if (data['user'] is Map<String, dynamic>) {
          return data['user'] as Map<String, dynamic>;
        }

        return data;
      }

      return body;
    }

    return <String, dynamic>{};
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
