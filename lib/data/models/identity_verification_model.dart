class IdentityVerificationModel {
  final int id;
  final int bookingId;
  final String documentType;
  final String ktpName;
  final String ktpNumberMasked;
  final String photoPath;
  final double latitude;
  final double longitude;
  final String addressText;
  final String status;
  final DateTime? takenAt;
  final DateTime? createdAt;

  const IdentityVerificationModel({
    required this.id,
    required this.bookingId,
    required this.documentType,
    required this.ktpName,
    required this.ktpNumberMasked,
    required this.photoPath,
    required this.latitude,
    required this.longitude,
    required this.addressText,
    required this.status,
    required this.takenAt,
    required this.createdAt,
  });

  factory IdentityVerificationModel.fromJson(Map<String, dynamic> json) {
    return IdentityVerificationModel(
      id: _toInt(json['id']),
      bookingId: _toInt(json['booking_id']),
      documentType: json['document_type']?.toString() ?? 'ktp',
      ktpName: json['ktp_name']?.toString() ?? '',
      ktpNumberMasked: json['ktp_number_masked']?.toString() ?? '',
      photoPath: json['photo_path']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      addressText: json['address_text']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      takenAt: _toDateTime(json['taken_at']),
      createdAt: _toDateTime(json['created_at']),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
