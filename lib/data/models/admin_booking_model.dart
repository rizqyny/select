class AdminBookingModel {
  final int id;
  final String code;
  final String status;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final DateTime? rentalStartDate;
  final DateTime? rentalEndDate;
  final String? customerNote;
  final num totalAmount;
  final String? paymentStatus;
  final DateTime? createdAt;
  final List<AdminBookingItemModel> items;

  const AdminBookingModel({
    required this.id,
    required this.code,
    required this.status,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.rentalStartDate,
    required this.rentalEndDate,
    required this.customerNote,
    required this.totalAmount,
    required this.paymentStatus,
    required this.createdAt,
    this.items = const [],
  });

  factory AdminBookingModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] ?? json['user'];
    final customerSource = customer is Map<String, dynamic>
        ? customer
        : <String, dynamic>{};

    return AdminBookingModel(
      id: _toInt(json['id']),
      code:
          json['booking_code']?.toString() ??
          json['booking_number']?.toString() ??
          json['code']?.toString() ??
          'BOOK-${_toInt(json['id'])}',
      status: json['status']?.toString() ?? '-',
      customerName:
          customerSource['full_name']?.toString() ??
          customerSource['name']?.toString() ??
          json['customer_name']?.toString() ??
          'Customer',
      customerEmail:
          customerSource['email']?.toString() ??
          json['customer_email']?.toString() ??
          '-',
      customerPhone:
          customerSource['phone']?.toString() ??
          json['customer_phone']?.toString() ??
          '-',
      rentalStartDate: _toDateTime(
        json['rental_start_date'] ?? json['start_date'] ?? json['startDate'],
      ),
      rentalEndDate: _toDateTime(
        json['rental_end_date'] ?? json['end_date'] ?? json['endDate'],
      ),
      customerNote:
          json['customer_note']?.toString() ?? json['notes']?.toString(),
      totalAmount: _toNum(
        json['total_amount'] ??
            json['total_price'] ??
            json['gross_amount'] ??
            json['grand_total'] ??
            json['amount'],
      ),
      paymentStatus: json['payment_status']?.toString(),
      createdAt: _toDateTime(json['created_at']),
      items: _parseItems(json),
    );
  }

  bool get canApprove {
    return status == 'paid' ||
        status == 'payment_pending' ||
        status == 'waiting_admin_approval';
  }

  bool get canReject {
    return status == 'pending_verification' ||
        status == 'waiting_payment' ||
        status == 'payment_pending' ||
        status == 'paid';
  }

  bool get canStart {
    return status == 'approved';
  }

  bool get canComplete {
    return status == 'ongoing' || status == 'active';
  }

  int get rentalDayCount {
    final start = rentalStartDate;
    final end = rentalEndDate;

    if (start == null || end == null) return 1;

    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    final diff = normalizedEnd.difference(normalizedStart).inDays;

    return diff < 0 ? 1 : diff + 1;
  }

  num get fallbackDailyPricePerItem {
    final itemCount = items.isEmpty ? 1 : items.length;
    final days = rentalDayCount <= 0 ? 1 : rentalDayCount;

    if (totalAmount <= 0) return 0;

    return totalAmount / days / itemCount;
  }

  static List<AdminBookingItemModel> _parseItems(Map<String, dynamic> json) {
    final raw =
        json['items'] ??
        json['booking_items'] ??
        json['bookingItems'] ??
        json['booking_details'] ??
        json['bookingDetails'];

    if (raw is! List) return <AdminBookingItemModel>[];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(AdminBookingItemModel.fromJson)
        .toList();
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static num _toNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class AdminBookingItemModel {
  final int id;
  final int itemId;
  final String itemName;
  final String brand;
  final num dailyPrice;

  const AdminBookingItemModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.brand,
    required this.dailyPrice,
  });

  factory AdminBookingItemModel.fromJson(Map<String, dynamic> json) {
    final item = json['item'] ?? json['items'];

    if (item is Map<String, dynamic>) {
      return AdminBookingItemModel(
        id: _toInt(json['id']),
        itemId: _toInt(item['id'] ?? json['item_id']),
        itemName:
            item['name']?.toString() ??
            json['item_name']?.toString() ??
            'Barang',
        brand: item['brand']?.toString() ?? '-',
        dailyPrice: _toNum(
          item['daily_price'] ??
              json['daily_price'] ??
              json['unit_price'] ??
              json['price_per_day'],
        ),
      );
    }

    return AdminBookingItemModel(
      id: _toInt(json['id']),
      itemId: _toInt(json['item_id']),
      itemName:
          json['item_name']?.toString() ?? json['name']?.toString() ?? 'Barang',
      brand: json['brand']?.toString() ?? '-',
      dailyPrice: _toNum(
        json['daily_price'] ?? json['unit_price'] ?? json['price_per_day'],
      ),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static num _toNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }
}
