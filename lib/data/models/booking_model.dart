class BookingModel {
  final int id;
  final String code;
  final String status;
  final DateTime? rentalStartDate;
  final DateTime? rentalEndDate;
  final String? customerNote;
  final num totalAmount;
  final String? paymentStatus;
  final DateTime? createdAt;
  final List<BookingItemSummary> items;
  final bool hasIdentityVerification;

  const BookingModel({
    required this.id,
    required this.code,
    required this.status,
    required this.rentalStartDate,
    required this.rentalEndDate,
    required this.customerNote,
    required this.totalAmount,
    required this.paymentStatus,
    required this.createdAt,
    this.items = const [],
    this.hasIdentityVerification = false,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: _toInt(json['id']),
      code:
          json['booking_code']?.toString() ??
          json['booking_number']?.toString() ??
          json['code']?.toString() ??
          json['order_id']?.toString() ??
          'BOOK-${_toInt(json['id'])}',
      status: json['status']?.toString() ?? '-',
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
      hasIdentityVerification: _parseHasIdentityVerification(json),
    );
  }

  bool get canPay {
    return status == 'waiting_payment' || status == 'payment_pending';
  }

  bool get needsIdentityVerification {
    return status == 'pending_verification';
  }

  bool get isRejectedOrCancelled {
    return status == 'rejected' || status == 'cancelled' || status == 'expired';
  }

  bool get isPaidOrProcessed {
    return status == 'paid' ||
        status == 'approved' ||
        status == 'ongoing' ||
        status == 'completed';
  }

  int get rentalDayCount {
    final start = rentalStartDate;
    final end = rentalEndDate;

    if (start == null || end == null) return 1;

    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    final diff = normalizedEnd.difference(normalizedStart).inDays;

    // Sistem sewa biasanya inklusif: 16-21 = 6 hari.
    return diff < 0 ? 1 : diff + 1;
  }

  num get fallbackDailyPricePerItem {
    final itemCount = items.isEmpty ? 1 : items.length;
    final days = rentalDayCount <= 0 ? 1 : rentalDayCount;

    if (totalAmount <= 0) return 0;

    return totalAmount / days / itemCount;
  }

  static List<BookingItemSummary> _parseItems(Map<String, dynamic> json) {
    final raw =
        json['items'] ??
        json['booking_items'] ??
        json['bookingItems'] ??
        json['booking_details'] ??
        json['bookingDetails'];

    if (raw is! List) return <BookingItemSummary>[];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(BookingItemSummary.fromJson)
        .toList();
  }

  static bool _parseHasIdentityVerification(Map<String, dynamic> json) {
    final direct =
        json['has_identity_verification'] ??
        json['identity_verification_submitted'] ??
        json['hasIdentityVerification'];

    if (direct is bool) return direct;

    final identityVerification =
        json['identity_verification'] ?? json['identityVerification'];

    if (identityVerification is Map<String, dynamic>) {
      return identityVerification.isNotEmpty;
    }

    final identityVerifications =
        json['identity_verifications'] ??
        json['identityVerifications'] ??
        json['verifications'];

    if (identityVerifications is List) {
      return identityVerifications.isNotEmpty;
    }

    return false;
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

class BookingItemSummary {
  final int id;
  final int itemId;
  final String itemName;
  final String imageUrl;
  final num dailyPrice;

  const BookingItemSummary({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.imageUrl,
    required this.dailyPrice,
  });

  factory BookingItemSummary.fromJson(Map<String, dynamic> json) {
    final item = json['item'] ?? json['items'];

    if (item is Map<String, dynamic>) {
      final primaryImage = item['primary_image'] ?? item['primaryImage'];

      return BookingItemSummary(
        id: _toInt(json['id']),
        itemId: _toInt(item['id'] ?? json['item_id']),
        itemName:
            item['name']?.toString() ??
            json['item_name']?.toString() ??
            'Barang',
        imageUrl: _imageUrlFromPrimaryImage(primaryImage),
        dailyPrice: _toNum(
          item['daily_price'] ??
              item['dailyPrice'] ??
              json['daily_price'] ??
              json['dailyPrice'] ??
              json['price_per_day'] ??
              json['pricePerDay'] ??
              json['unit_price'] ??
              json['unitPrice'] ??
              json['rental_price'] ??
              json['rentalPrice'],
        ),
      );
    }

    return BookingItemSummary(
      id: _toInt(json['id']),
      itemId: _toInt(json['item_id']),
      itemName:
          json['item_name']?.toString() ?? json['name']?.toString() ?? 'Barang',
      imageUrl: json['image_url']?.toString() ?? '',
      dailyPrice: _toNum(
        json['daily_price'] ??
            json['dailyPrice'] ??
            json['price_per_day'] ??
            json['pricePerDay'] ??
            json['unit_price'] ??
            json['unitPrice'] ??
            json['rental_price'] ??
            json['rentalPrice'],
      ),
    );
  }

  static String _imageUrlFromPrimaryImage(Object? value) {
    if (value is Map<String, dynamic>) {
      final url =
          value['public_url']?.toString() ??
          value['publicUrl']?.toString() ??
          '';

      if (url.contains('example.com')) return '';
      return url;
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
