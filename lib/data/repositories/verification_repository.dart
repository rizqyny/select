import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../models/identity_verification_model.dart';

class VerificationRepository {
  final Dio _dio;

  const VerificationRepository({required Dio dio}) : _dio = dio;

  Future<IdentityVerificationModel> submitIdentityVerification({
    required int bookingId,
    required String ktpName,
    required String ktpNumberMasked,
    required String photoPath,
    required double latitude,
    required double longitude,
    required String addressText,
    required DateTime takenAt,
  }) async {
    try {
      final payload = {
        'booking_id': bookingId,
        'document_type': 'ktp',
        'ktp_name': ktpName.trim(),
        'ktp_number_masked': ktpNumberMasked.trim(),
        'photo_path': photoPath,
        'latitude': latitude,
        'longitude': longitude,
        'address_text': addressText,
        'taken_at': takenAt.toUtc().toIso8601String(),

        // Cadangan kalau backend memakai nama field berbeda
        'document_name': ktpName.trim(),
        'document_number': ktpNumberMasked.trim(),
        'document_photo_path': photoPath,
        'location_latitude': latitude,
        'location_longitude': longitude,
        'location_address': addressText,
      };

      print('IDENTITY VERIFY PAYLOAD: $payload');

      final response = await _dio.post(
        ApiConstants.identityVerification,
        data: payload,
      );

      print('IDENTITY VERIFY RESPONSE STATUS: ${response.statusCode}');
      print('IDENTITY VERIFY RESPONSE DATA: ${response.data}');

      final body = response.data;

      if (body is Map<String, dynamic>) {
        final data = body['data'];

        if (data is Map<String, dynamic>) {
          return IdentityVerificationModel.fromJson(data);
        }

        if (body.containsKey('id')) {
          return IdentityVerificationModel.fromJson(body);
        }
      }

      throw Exception('Format response verifikasi identitas tidak valid.');
    } on DioException catch (error) {
      print('IDENTITY VERIFY DIO ERROR STATUS: ${error.response?.statusCode}');
      print('IDENTITY VERIFY DIO ERROR DATA: ${error.response?.data}');

      throw Exception(
        'Gagal submit verifikasi KTP: ${_extractErrorMessage(error)}',
      );
    } catch (error) {
      print('IDENTITY VERIFY ERROR: $error');
      throw Exception('Gagal submit verifikasi KTP: $error');
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
