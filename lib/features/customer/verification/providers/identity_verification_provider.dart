import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/device/models/captured_location.dart';
import '../../../../core/device/services/location_service.dart';
import '../../../../data/models/identity_verification_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/storage_repository.dart';
import '../../../../data/repositories/verification_repository.dart';

const Object _unset = Object();

class IdentityVerificationState {
  final int bookingId;
  final String ktpName;
  final String ktpNumber;
  final String? imagePath;
  final CapturedLocation? location;
  final IdentityVerificationModel? result;
  final bool isGettingLocation;
  final bool isSubmitting;
  final String? errorMessage;

  const IdentityVerificationState({
    required this.bookingId,
    this.ktpName = '',
    this.ktpNumber = '',
    this.imagePath,
    this.location,
    this.result,
    this.isGettingLocation = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  IdentityVerificationState copyWith({
    String? ktpName,
    String? ktpNumber,
    Object? imagePath = _unset,
    Object? location = _unset,
    Object? result = _unset,
    bool? isGettingLocation,
    bool? isSubmitting,
    Object? errorMessage = _unset,
  }) {
    return IdentityVerificationState(
      bookingId: bookingId,
      ktpName: ktpName ?? this.ktpName,
      ktpNumber: ktpNumber ?? this.ktpNumber,
      imagePath: identical(imagePath, _unset)
          ? this.imagePath
          : imagePath as String?,
      location: identical(location, _unset)
          ? this.location
          : location as CapturedLocation?,
      result: identical(result, _unset)
          ? this.result
          : result as IdentityVerificationModel?,
      isGettingLocation: isGettingLocation ?? this.isGettingLocation,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  bool get canSubmit {
    return ktpName.trim().isNotEmpty &&
        ktpNumber.trim().length >= 8 &&
        imagePath != null &&
        location != null &&
        !isSubmitting &&
        !isGettingLocation;
  }
}

final identityVerificationControllerProvider =
    AsyncNotifierProvider.family<
      IdentityVerificationController,
      IdentityVerificationState,
      int
    >(IdentityVerificationController.new);
String _cleanErrorMessage(Object error) {
  final message = error.toString().replaceFirst('Exception: ', '');

  if (message.toLowerCase().contains('internal server error')) {
    return 'Gagal mengambil alamat lokasi. Coba tekan Ambil Lokasi GPS lagi atau lanjutkan dengan koordinat GPS.';
  }

  return message;
}

class IdentityVerificationController
    extends AsyncNotifier<IdentityVerificationState> {
  final int bookingId;

  IdentityVerificationController(this.bookingId);

  final LocationService _locationService = const LocationService();

  StorageRepository get _storageRepository =>
      ref.read(storageRepositoryProvider);

  VerificationRepository get _verificationRepository =>
      ref.read(verificationRepositoryProvider);

  @override
  FutureOr<IdentityVerificationState> build() {
    return IdentityVerificationState(bookingId: bookingId);
  }

  void setKtpName(String value) {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(ktpName: value, errorMessage: null));
  }

  void setKtpNumber(String value) {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(ktpNumber: value, errorMessage: null));
  }

  void setImagePath(String path) {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(imagePath: path, errorMessage: null));
  }

  Future<void> getCurrentLocation() async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(isGettingLocation: true, errorMessage: null),
    );

    try {
      final location = await _locationService.getCurrentLocation();

      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          location: location,
          isGettingLocation: false,
          errorMessage: null,
        ),
      );
    } catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          isGettingLocation: false,
          errorMessage: _cleanErrorMessage(error),
        ),
      );
    }
  }

  Future<IdentityVerificationModel?> submit() async {
    final current = state.value;

    if (current == null) return null;

    final imagePath = current.imagePath;
    final location = current.location;

    if (!current.canSubmit || imagePath == null || location == null) {
      state = AsyncData(
        current.copyWith(
          errorMessage:
              'Lengkapi nama KTP, nomor KTP, foto KTP, dan lokasi GPS terlebih dahulu.',
        ),
      );
      return null;
    }

    state = AsyncData(current.copyWith(isSubmitting: true, errorMessage: null));

    try {
      final file = File(imagePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'ktp/booking-$bookingId/ktp-$timestamp.jpg';

      final uploadedPath = await _storageRepository.uploadPrivateFile(
        file: file,
        bucket: 'identity-documents',
        path: storagePath,
        contentType: 'image/jpeg',
      );

      final result = await _verificationRepository.submitIdentityVerification(
        bookingId: bookingId,
        ktpName: current.ktpName,
        ktpNumberMasked: _maskKtpNumber(current.ktpNumber),
        photoPath: uploadedPath,
        latitude: location.latitude,
        longitude: location.longitude,
        addressText: location.addressText,
        takenAt: location.takenAt,
      );

      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          result: result,
          isSubmitting: false,
          errorMessage: null,
        ),
      );

      return result;
    } catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          isSubmitting: false,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      return null;
    }
  }

  String _maskKtpNumber(String value) {
    final clean = value.replaceAll(RegExp(r'\D'), '');

    if (clean.length <= 8) {
      return clean;
    }

    final start = clean.substring(0, 4);
    final end = clean.substring(clean.length - 4);

    return '$start********$end';
  }
}
