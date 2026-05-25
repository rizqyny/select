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

  AuthRepository({
    required Dio dio,
    required SupabaseClient supabase,
  })  : _dio = dio,
        _supabase = supabase;

  bool get hasSession => _supabase.auth.currentSession != null;

  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.session == null || response.user == null) {
        throw const ApiException(
          message: 'Login gagal. Session tidak ditemukan.',
        );
      }

      return getCurrentUser();
    } on AuthException catch (error) {
      throw ApiException(message: _mapAuthError(error.message));
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException(message: error.toString());
    }
  }

  Future<void> _initializeGoogleSignIn() async {
    if (_googleInitialized) return;

    if (!AppEnv.isGoogleConfigured) {
      throw const ApiException(
        message: 'Google Login belum dikonfigurasi.',
      );
    }

    await GoogleSignIn.instance.initialize(
      serverClientId: AppEnv.googleWebClientId,
    );

    _googleInitialized = true;
  }

  Future<AppUser> signInWithGoogle() async {
    try {
      await _initializeGoogleSignIn();

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw const ApiException(
          message: 'Google Sign-In tidak didukung di device ini.',
        );
      }

      final googleAccount = await GoogleSignIn.instance.authenticate();
      final googleAuthentication = googleAccount.authentication;

      final idToken = googleAuthentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(
          message: 'ID Token Google tidak ditemukan.',
        );
      }

      final googleAuthorization = await googleAccount.authorizationClient
          .authorizationForScopes(<String>[]);

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuthorization?.accessToken,
      );

      return getCurrentUser();
    } on ApiException {
      rethrow;
    } on AuthException catch (error) {
      throw ApiException(message: _mapAuthError(error.message));
    } catch (error) {
      throw ApiException(message: error.toString());
    }
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

      final apiResponse = ApiResponse<AppUser>.fromJson(
        body,
        (json) {
          if (json is Map<String, dynamic>) {
            return AppUser.fromJson(json);
          }

          throw const ApiException(
            message: 'Data profil tidak valid.',
          );
        },
      );

      final user = apiResponse.data;

      if (user == null) {
        throw ApiException(
          message: apiResponse.message.isNotEmpty
              ? apiResponse.message
              : 'Profil user tidak ditemukan.',
        );
      }

      if (!user.isActive) {
        throw const ApiException(
          message: 'Akun kamu sedang tidak aktif.',
        );
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

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('invalid login credentials')) {
      return 'Email atau password salah.';
    }

    if (lower.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi.';
    }

    if (lower.contains('user not found')) {
      return 'Akun tidak ditemukan.';
    }

    return message;
  }
}