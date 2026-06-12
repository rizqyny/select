import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/repository_providers.dart';
import '../../../data/repositories/register_repository.dart';

class RegisterState {
  final bool isSubmitting;
  final String? errorMessage;

  const RegisterState({this.isSubmitting = false, this.errorMessage});

  RegisterState copyWith({bool? isSubmitting, String? errorMessage}) {
    return RegisterState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

final registerControllerProvider =
    AsyncNotifierProvider<RegisterController, RegisterState>(
      RegisterController.new,
    );

class RegisterController extends AsyncNotifier<RegisterState> {
  RegisterRepository get _repository => ref.read(registerRepositoryProvider);

  @override
  FutureOr<RegisterState> build() {
    return const RegisterState();
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
  }) async {
    final current = state.value ?? const RegisterState();

    if (fullName.trim().isEmpty) {
      state = AsyncData(
        current.copyWith(errorMessage: 'Nama lengkap tidak boleh kosong.'),
      );
      return false;
    }

    if (email.trim().isEmpty) {
      state = AsyncData(
        current.copyWith(errorMessage: 'Email tidak boleh kosong.'),
      );
      return false;
    }

    if (password.length < 6) {
      state = AsyncData(
        current.copyWith(errorMessage: 'Password minimal 6 karakter.'),
      );
      return false;
    }

    if (password != confirmPassword) {
      state = AsyncData(
        current.copyWith(errorMessage: 'Konfirmasi password tidak sama.'),
      );
      return false;
    }

    state = const AsyncData(
      RegisterState(isSubmitting: true, errorMessage: null),
    );

    try {
      await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );

      state = const AsyncData(RegisterState());
      return true;
    } catch (error) {
      state = AsyncData(
        RegisterState(
          isSubmitting: false,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }
}
