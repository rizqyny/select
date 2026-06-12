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
    final current = state.asData?.value ?? const RegisterState();

    final cleanFullName = fullName.trim();
    final cleanPhone = phone.trim();
    final cleanEmail = _normalizeEmail(email);

    if (cleanFullName.isEmpty) {
      state = AsyncData(
        current.copyWith(errorMessage: 'Nama lengkap tidak boleh kosong.'),
      );
      return false;
    }

    if (cleanPhone.isEmpty) {
      state = AsyncData(
        current.copyWith(errorMessage: 'Nomor HP tidak boleh kosong.'),
      );
      return false;
    }

    if (cleanEmail.isEmpty) {
      state = AsyncData(
        current.copyWith(errorMessage: 'Email tidak boleh kosong.'),
      );
      return false;
    }

    if (!_isValidEmail(cleanEmail)) {
      state = AsyncData(
        current.copyWith(
          errorMessage: 'Format email tidak valid. Contoh: nama@gmail.com',
        ),
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
        fullName: cleanFullName,
        email: cleanEmail,
        password: password,
        phone: cleanPhone,
      );

      state = const AsyncData(RegisterState());
      return true;
    } catch (error) {
      state = AsyncData(
        RegisterState(
          isSubmitting: false,
          errorMessage: _cleanRegisterError(error.toString()),
        ),
      );
      return false;
    }
  }

  String _normalizeEmail(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  bool _isValidEmail(String value) {
    final regex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );

    return regex.hasMatch(value);
  }

  String _cleanRegisterError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('email rate limit exceeded')) {
      return 'Terlalu banyak percobaan register/email. Tunggu beberapa menit atau gunakan email lain.';
    }

    if (lower.contains('email') && lower.contains('invalid')) {
      return 'Email tidak valid. Pastikan format email benar, contoh: nama@gmail.com';
    }

    if (lower.contains('already') ||
        lower.contains('registered') ||
        lower.contains('exists')) {
      return 'Email sudah terdaftar. Silakan login atau gunakan email lain.';
    }

    return message.replaceFirst('Exception: ', '');
  }
}
