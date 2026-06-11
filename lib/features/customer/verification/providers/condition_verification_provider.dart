import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/device/models/captured_location.dart';
import '../../../../core/device/services/location_service.dart';
import '../../../../data/models/condition_verification_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/repositories/storage_repository.dart';
import '../../../../data/repositories/verification_repository.dart';

class ConditionVerificationArgs {
  final int bookingId;
  final int itemId;
  final String type;

  const ConditionVerificationArgs({
    required this.bookingId,
    required this.itemId,
    required this.type,
  });

  String get localKey => 'condition_verification_${bookingId}_${itemId}_$type';

  String get title {
    if (type == 'after_rent') {
      return 'Kondisi Akhir Barang';
    }

    return 'Kondisi Awal Barang';
  }

  String get storageFolder {
    return 'before-rent';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ConditionVerificationArgs &&
            other.bookingId == bookingId &&
            other.itemId == itemId &&
            other.type == type;
  }

  @override
  int get hashCode => Object.hash(bookingId, itemId, type);
}

class ConditionVerificationState {
  final String imagePath;
  final String note;
  final CapturedLocation? location;
  final bool isGettingLocation;
  final bool isSubmitting;
  final String? errorMessage;
  final ConditionVerificationModel? result;

  const ConditionVerificationState({
    this.imagePath = '',
    this.note = '',
    this.location,
    this.isGettingLocation = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.result,
  });

  bool get canSubmit {
    return imagePath.trim().isNotEmpty &&
        location != null &&
        !isGettingLocation &&
        !isSubmitting;
  }

  ConditionVerificationState copyWith({
    String? imagePath,
    String? note,
    Object? location = _unset,
    bool? isGettingLocation,
    bool? isSubmitting,
    Object? errorMessage = _unset,
    Object? result = _unset,
  }) {
    return ConditionVerificationState(
      imagePath: imagePath ?? this.imagePath,
      note: note ?? this.note,
      location: identical(location, _unset)
          ? this.location
          : location as CapturedLocation?,
      isGettingLocation: isGettingLocation ?? this.isGettingLocation,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      result: identical(result, _unset)
          ? this.result
          : result as ConditionVerificationModel?,
    );
  }
}

const Object _unset = Object();

final conditionVerificationControllerProvider =
    AsyncNotifierProvider.family<
      ConditionVerificationController,
      ConditionVerificationState,
      ConditionVerificationArgs
    >(ConditionVerificationController.new);

class ConditionVerificationController
    extends AsyncNotifier<ConditionVerificationState> {
  final ConditionVerificationArgs args;

  ConditionVerificationController(this.args);

  StorageRepository get _storageRepository =>
      ref.read(storageRepositoryProvider);

  VerificationRepository get _verificationRepository =>
      ref.read(verificationRepositoryProvider);

  final LocationService _locationService = const LocationService();

  @override
  FutureOr<ConditionVerificationState> build() {
    return const ConditionVerificationState();
  }

  void setImagePath(String path) {
    final current = state.value ?? const ConditionVerificationState();

    state = AsyncData(current.copyWith(imagePath: path, errorMessage: null));
  }

  void setNote(String note) {
    final current = state.value ?? const ConditionVerificationState();

    state = AsyncData(current.copyWith(note: note, errorMessage: null));
  }

  Future<void> getCurrentLocation() async {
    final current = state.value ?? const ConditionVerificationState();

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
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<bool> submit() async {
    final current = state.value ?? const ConditionVerificationState();

    if (!current.canSubmit || current.location == null) {
      state = AsyncData(
        current.copyWith(
          errorMessage: 'Foto barang dan lokasi GPS wajib diisi.',
        ),
      );
      return false;
    }

    state = AsyncData(current.copyWith(isSubmitting: true, errorMessage: null));

    try {
      final file = File(current.imagePath);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath =
          'condition/booking-${args.bookingId}/item-${args.itemId}/${args.storageFolder}-$timestamp.jpg';

      final uploadedPath = await _storageRepository.uploadPrivateFile(
        file: file,
        bucket: 'condition-photos',
        path: storagePath,
        contentType: 'image/jpeg',
      );

      final location = current.location!;

      final result = await _verificationRepository.submitConditionVerification(
        bookingId: args.bookingId,
        itemId: args.itemId,
        type: args.type,
        photoPath: uploadedPath,
        latitude: location.latitude,
        longitude: location.longitude,
        addressText: location.addressText,
        note: current.note,
        takenAt: location.takenAt,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(args.localKey, true);

      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          isSubmitting: false,
          errorMessage: null,
          result: result,
        ),
      );

      return true;
    } catch (error) {
      final latest = state.value ?? current;

      state = AsyncData(
        latest.copyWith(
          isSubmitting: false,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );

      return false;
    }
  }
}
