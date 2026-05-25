import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/dio_client.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    supabase: Supabase.instance.client,
  );
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);

class AuthController extends AsyncNotifier<AppUser?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  FutureOr<AppUser?> build() {
    return null;
  }

  Future<void> loadCurrentUser() async {
    if (!_repository.hasSession) {
      state = const AsyncData(null);
      return;
    }

    state = const AsyncLoading();

    try {
      final user = await _repository.getCurrentUser();
      state = AsyncData(user);
    } catch (error, stackTrace) {
      await _repository.signOut();
      state = AsyncError(error, stackTrace);
    }
  }

  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final user = await _repository.signInWithEmailPassword(
        email: email,
        password: password,
      );
      state = AsyncData(user);
      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<AppUser> signInWithGoogle() async {
    state = const AsyncLoading();

    try {
      final user = await _repository.signInWithGoogle();
      state = AsyncData(user);
      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();

    try {
      await _repository.signOut();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}