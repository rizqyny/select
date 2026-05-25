import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/api_constants.dart';
import '../../core/env/app_env.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_response.dart';
import '../models/app_user.dart';

class AuthRepository {
  final Dio _dio;
  final SupabaseClient _supabase;

  bool _googleInitialized = false;

  AuthRepository({required Dio dio, required SupabaseClient supabase})
    : _dio = dio,
      _supabase = supabase;

  bool get hasSession => _supabase.auth.currentSession != null;

  Future<void> _initializeGoogleSignIn() async {
    if (_googleInitialized) return;

    await GoogleSignIn.instance.initialize(
      serverClientId: AppEnv.googleWebClientId,
    );

    _googleInitialized = true;
  }

  Future<AppUser> signInWithGoogle() async {
    await _initializeGoogleSignIn();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw Exception('Google Sign-In tidak didukung di device ini.');
    }

    final googleAccount = await GoogleSignIn.instance.authenticate();
    final googleAuthentication = googleAccount.authentication;

    final idToken = googleAuthentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception('ID Token Google tidak ditemukan.');
    }

    final googleAuthorization = await googleAccount.authorizationClient
        .authorizationForScopes(<String>[]);

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuthorization?.accessToken,
    );

    return getCurrentUser();
  }

  Future<AppUser> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.usersMe);

      final body = response.data;

      if (body is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Format response profil tidak valid.',
        );
      }

      final apiResponse = ApiResponse<AppUser>.fromJson(body, (json) {
        if (json is Map<String, dynamic>) {
          return AppUser.fromJson(json);
        }

        throw const ApiException(message: 'Data profil tidak valid.');
      });

      final user = apiResponse.data;

      if (user == null) {
        throw ApiException(
          message: apiResponse.message.isNotEmpty
              ? apiResponse.message
              : 'Profil user tidak ditemukan.',
        );
      }

      if (!user.isActive) {
        throw const ApiException(message: 'Akun kamu sedang tidak aktif.');
      }

      return user;
    } on DioException catch (error) {
      final err = error.error;

      if (err is ApiException) {
        throw err;
      }

      throw ApiException.fromDio(error);
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();

    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
  }
}
