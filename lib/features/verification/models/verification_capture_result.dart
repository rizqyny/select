import '../../location/models/captured_location.dart';

enum VerificationCaptureType {
  identity,
  beforeRent,
  afterRent,
}

extension VerificationCaptureTypeX on VerificationCaptureType {
  String get title {
    switch (this) {
      case VerificationCaptureType.identity:
        return 'Foto KTP';
      case VerificationCaptureType.beforeRent:
        return 'Foto Kondisi Awal';
      case VerificationCaptureType.afterRent:
        return 'Foto Kondisi Akhir';
    }
  }

  String get apiType {
    switch (this) {
      case VerificationCaptureType.identity:
        return 'ktp';
      case VerificationCaptureType.beforeRent:
        return 'before_rent';
      case VerificationCaptureType.afterRent:
        return 'after_rent';
    }
  }
}

class VerificationCaptureArgs {
  final int? bookingId;
  final int? itemId;
  final VerificationCaptureType type;

  const VerificationCaptureArgs({
    this.bookingId,
    this.itemId,
    required this.type,
  });
}

class VerificationCaptureResult {
  final String imagePath;
  final CapturedLocation location;
  final VerificationCaptureType type;

  const VerificationCaptureResult({
    required this.imagePath,
    required this.location,
    required this.type,
  });
}