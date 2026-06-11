class ConditionVerificationModel {
  final int id;
  final int bookingId;
  final int itemId;
  final String type;
  final String photoPath;
  final double latitude;
  final double longitude;
  final String addressText;
  final String note;
  final String status;
  final DateTime? takenAt;
  final DateTime? createdAt;

  const ConditionVerificationModel({
    required this.id,
    required this.bookingId,
    required this.itemId,
    required this.type,
    required this.photoPath,
    required this.latitude,
    required this.longitude,
    required this.addressText,
    required this.note,
    required this.status,
    required this.takenAt,
    required this.createdAt,
  });

  factory ConditionVerificationModel.fromJson(Map<String, dynamic> json) {
    return ConditionVerificationModel(
      id: _toInt(json['id']),
      bookingId: _toInt(json['booking_id']),
      itemId: _toInt(json['item_id']),
      type: json['type']?.toString() ?? '',
      photoPath: json['photo_path']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      addressText: json['address_text']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
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
