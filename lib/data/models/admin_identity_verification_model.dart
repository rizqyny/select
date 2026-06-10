class AdminIdentityVerificationModel {
  final int id;
  final int bookingId;
  final String bookingCode;
  final String customerName;
  final String customerEmail;
  final String documentType;
  final String ktpName;
  final String ktpNumberMasked;
  final String photoPath;
  final double latitude;
  final double longitude;
  final String addressText;
  final String status;
  final String? adminNote;
  final DateTime? takenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminIdentityVerificationModel({
    required this.id,
    required this.bookingId,
    required this.bookingCode,
    required this.customerName,
    required this.customerEmail,
    required this.documentType,
    required this.ktpName,
    required this.ktpNumberMasked,
    required this.photoPath,
    required this.latitude,
    required this.longitude,
    required this.addressText,
    required this.status,
    required this.adminNote,
    required this.takenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminIdentityVerificationModel.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'];
    final customer = json['customer'] ?? json['user'];

    final nestedCustomer = booking is Map<String, dynamic>
        ? booking['customer'] ?? booking['user']
        : null;

    final customerSource = customer is Map<String, dynamic>
        ? customer
        : nestedCustomer is Map<String, dynamic>
        ? nestedCustomer
        : <String, dynamic>{};

    return AdminIdentityVerificationModel(
      id: _toInt(json['id']),
      bookingId: _toInt(
        json['booking_id'] ??
            (booking is Map<String, dynamic> ? booking['id'] : null),
      ),
      bookingCode:
          json['booking_code']?.toString() ??
          (booking is Map<String, dynamic>
              ? booking['booking_code']?.toString() ??
                    booking['code']?.toString() ??
                    'BOOK-${_toInt(booking['id'])}'
              : 'BOOK-${_toInt(json['booking_id'])}'),
      customerName:
          customerSource['full_name']?.toString() ??
          customerSource['name']?.toString() ??
          'Customer',
      customerEmail: customerSource['email']?.toString() ?? '-',
      documentType: json['document_type']?.toString() ?? 'ktp',
      ktpName: json['ktp_name']?.toString() ?? '',
      ktpNumberMasked: json['ktp_number_masked']?.toString() ?? '',
      photoPath: json['photo_path']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      addressText: json['address_text']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      adminNote:
          json['admin_note']?.toString() ??
          json['rejection_reason']?.toString(),
      takenAt: _toDateTime(json['taken_at']),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  bool get isPending => status == 'pending' || status == 'pending_review';

  bool get isApproved => status == 'approved';

  bool get isRejected => status == 'rejected';

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
