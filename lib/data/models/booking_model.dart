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
      rentalStartDate: _toDateTime(json['rental_start_date']),
      rentalEndDate: _toDateTime(json['rental_end_date']),
      customerNote: json['customer_note']?.toString(),
      totalAmount: _toNum(
        json['total_amount'] ??
            json['total_price'] ??
            json['gross_amount'] ??
            json['grand_total'],
      ),
      paymentStatus: json['payment_status']?.toString(),
      createdAt: _toDateTime(json['created_at']),
      items: _parseItems(json),
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

  static List<BookingItemSummary> _parseItems(Map<String, dynamic> json) {
    final raw =
        json['items'] ??
        json['booking_items'] ??
        json['bookingItems'] ??
        json['booking_details'];

    if (raw is! List) return <BookingItemSummary>[];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(BookingItemSummary.fromJson)
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
    final item = json['item'];

    if (item is Map<String, dynamic>) {
      final primaryImage = item['primary_image'];

      return BookingItemSummary(
        id: _toInt(json['id']),
        itemId: _toInt(item['id'] ?? json['item_id']),
        itemName: item['name']?.toString() ?? 'Barang',
        imageUrl: _imageUrlFromPrimaryImage(primaryImage),
        dailyPrice: _toNum(item['daily_price'] ?? json['daily_price']),
      );
    }

    return BookingItemSummary(
      id: _toInt(json['id']),
      itemId: _toInt(json['item_id']),
      itemName:
          json['item_name']?.toString() ?? json['name']?.toString() ?? 'Barang',
      imageUrl: json['image_url']?.toString() ?? '',
      dailyPrice: _toNum(json['daily_price']),
    );
  }

  static String _imageUrlFromPrimaryImage(Object? value) {
    if (value is Map<String, dynamic>) {
      final url = value['public_url']?.toString() ?? '';

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
