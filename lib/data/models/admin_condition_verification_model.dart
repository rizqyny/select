class AdminConditionVerificationModel {
  final int id;
  final int bookingId;
  final int itemId;
  final int userId;
  final String type;
  final String photoBucket;
  final String photoPath;
  final double latitude;
  final double longitude;
  final String addressText;
  final String note;
  final String status;
  final DateTime? takenAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime? createdAt;

  final AdminConditionBooking booking;
  final AdminConditionUser user;
  final AdminConditionItem item;

  const AdminConditionVerificationModel({
    required this.id,
    required this.bookingId,
    required this.itemId,
    required this.userId,
    required this.type,
    required this.photoBucket,
    required this.photoPath,
    required this.latitude,
    required this.longitude,
    required this.addressText,
    required this.note,
    required this.status,
    required this.takenAt,
    required this.reviewedAt,
    required this.rejectionReason,
    required this.createdAt,
    required this.booking,
    required this.user,
    required this.item,
  });

  factory AdminConditionVerificationModel.fromJson(Map<String, dynamic> json) {
    final bookingRaw = json['booking'];
    final userRaw = json['user'] ?? json['customer'] ?? json['submitter'];
    final itemRaw = json['item'];

    return AdminConditionVerificationModel(
      id: _toInt(json['id']),
      bookingId: _toInt(json['booking_id']),
      itemId: _toInt(json['item_id']),
      userId: _toInt(
        json['user_id'] ?? json['submitted_by'] ?? json['submittedBy'],
      ),
      type: json['type']?.toString() ?? '',
      photoBucket:
          json['photo_bucket']?.toString() ??
          json['bucket']?.toString() ??
          'condition-photos',
      photoPath:
          json['photo_path']?.toString() ?? json['photoPath']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      addressText: json['address_text']?.toString() ?? '-',
      note: json['note']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'pending',
      takenAt: _toDateTime(json['taken_at']),
      reviewedAt: _toDateTime(json['reviewed_at']),
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: _toDateTime(json['created_at']),
      booking: bookingRaw is Map<String, dynamic>
          ? AdminConditionBooking.fromJson(bookingRaw)
          : AdminConditionBooking.empty(_toInt(json['booking_id'])),
      user: userRaw is Map<String, dynamic>
          ? AdminConditionUser.fromJson(userRaw)
          : const AdminConditionUser(),
      item: itemRaw is Map<String, dynamic>
          ? AdminConditionItem.fromJson(itemRaw)
          : AdminConditionItem.empty(_toInt(json['item_id'])),
    );
  }

  bool get isBeforeRent => type == 'before_rent';

  bool get isPending => status == 'pending';

  bool get isApproved => status == 'approved';

  bool get isRejected => status == 'rejected';

  String get typeLabel {
    if (type == 'before_rent') return 'Kondisi Awal';
    if (type == 'after_rent') return 'Kondisi Akhir';
    return type;
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

class AdminConditionBooking {
  final int id;
  final String bookingCode;
  final String status;
  final DateTime? rentalStartDate;
  final DateTime? rentalEndDate;

  const AdminConditionBooking({
    required this.id,
    required this.bookingCode,
    required this.status,
    required this.rentalStartDate,
    required this.rentalEndDate,
  });

  factory AdminConditionBooking.fromJson(Map<String, dynamic> json) {
    return AdminConditionBooking(
      id: _toInt(json['id']),
      bookingCode:
          json['booking_code']?.toString() ??
          json['code']?.toString() ??
          'BOOK-${_toInt(json['id'])}',
      status: json['status']?.toString() ?? '-',
      rentalStartDate: _toDateTime(json['rental_start_date']),
      rentalEndDate: _toDateTime(json['rental_end_date']),
    );
  }

  factory AdminConditionBooking.empty(int id) {
    return AdminConditionBooking(
      id: id,
      bookingCode: 'BOOK-$id',
      status: '-',
      rentalStartDate: null,
      rentalEndDate: null,
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class AdminConditionUser {
  final int id;
  final String fullName;
  final String email;
  final String phone;

  const AdminConditionUser({
    this.id = 0,
    this.fullName = 'Customer',
    this.email = '-',
    this.phone = '-',
  });

  factory AdminConditionUser.fromJson(Map<String, dynamic> json) {
    return AdminConditionUser(
      id: _toInt(json['id']),
      fullName:
          json['full_name']?.toString() ??
          json['name']?.toString() ??
          'Customer',
      email: json['email']?.toString() ?? '-',
      phone: json['phone']?.toString() ?? '-',
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class AdminConditionItem {
  final int id;
  final String name;
  final String brand;
  final String model;
  final String serialNumber;

  const AdminConditionItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.serialNumber,
  });

  factory AdminConditionItem.fromJson(Map<String, dynamic> json) {
    return AdminConditionItem(
      id: _toInt(json['id'] ?? json['item_id']),
      name:
          json['name']?.toString() ??
          json['item_name']?.toString() ??
          json['item_name_snapshot']?.toString() ??
          'Barang',
      brand: json['brand']?.toString() ?? '-',
      model: json['model']?.toString() ?? '-',
      serialNumber: json['serial_number']?.toString() ?? '-',
    );
  }

  factory AdminConditionItem.empty(int id) {
    return AdminConditionItem(
      id: id,
      name: 'Barang',
      brand: '-',
      model: '-',
      serialNumber: '-',
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
