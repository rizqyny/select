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
  final String imageUrl;

  const AdminBookingItemModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.brand,
    required this.dailyPrice,
    required this.imageUrl,
  });

  factory AdminBookingItemModel.fromJson(Map<String, dynamic> json) {
    final item = json['item'] ?? json['items'];

    final itemMap = item is Map<String, dynamic> ? item : <String, dynamic>{};

    return AdminBookingItemModel(
      id: _toInt(json['id']),
      itemId: _toInt(itemMap['id'] ?? json['item_id']),
      itemName:
          itemMap['name']?.toString() ??
          json['item_name']?.toString() ??
          json['name']?.toString() ??
          'Barang',
      brand: itemMap['brand']?.toString() ?? json['brand']?.toString() ?? '-',
      dailyPrice: _toNum(
        itemMap['daily_price'] ??
            itemMap['dailyPrice'] ??
            itemMap['price_per_day'] ??
            itemMap['pricePerDay'] ??
            json['daily_price'] ??
            json['dailyPrice'] ??
            json['unit_price'] ??
            json['unitPrice'] ??
            json['price_per_day'] ??
            json['pricePerDay'],
      ),
      imageUrl: _extractImageUrl(json, itemMap),
    );
  }

  static String _extractImageUrl(
    Map<String, dynamic> json,
    Map<String, dynamic> item,
  ) {
    final directCandidates = [
      json['image_url'],
      json['imageUrl'],
      json['public_url'],
      json['publicUrl'],
      json['photo_url'],
      json['photoUrl'],
      item['image_url'],
      item['imageUrl'],
      item['public_url'],
      item['publicUrl'],
      item['photo_url'],
      item['photoUrl'],
    ];

    for (final value in directCandidates) {
      final url = value?.toString().trim() ?? '';

      if (url.isNotEmpty && !url.contains('example.com')) {
        return url;
      }
    }

    final primaryImage =
        item['primary_image'] ??
        item['primaryImage'] ??
        json['primary_image'] ??
        json['primaryImage'];

    if (primaryImage is Map<String, dynamic>) {
      final url =
          primaryImage['public_url']?.toString().trim() ??
          primaryImage['publicUrl']?.toString().trim() ??
          primaryImage['image_url']?.toString().trim() ??
          primaryImage['imageUrl']?.toString().trim() ??
          '';

      if (url.isNotEmpty && !url.contains('example.com')) {
        return url;
      }
    }

    final images =
        item['images'] ??
        item['item_images'] ??
        item['itemImages'] ??
        json['images'] ??
        json['item_images'] ??
        json['itemImages'];

    if (images is List) {
      for (final image in images) {
        if (image is Map<String, dynamic>) {
          final url =
              image['public_url']?.toString().trim() ??
              image['publicUrl']?.toString().trim() ??
              image['image_url']?.toString().trim() ??
              image['imageUrl']?.toString().trim() ??
              '';

          if (url.isNotEmpty && !url.contains('example.com')) {
            return url;
          }
        }
      }
    }

    return '';
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
