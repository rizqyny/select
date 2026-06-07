class BookingModel {
  final int id;
  final String code;
  final String status;
  final DateTime? rentalStartDate;
  final DateTime? rentalEndDate;
  final String? customerNote;
  final num totalAmount;
  final DateTime? createdAt;

  const BookingModel({
    required this.id,
    required this.code,
    required this.status,
    required this.rentalStartDate,
    required this.rentalEndDate,
    required this.customerNote,
    required this.totalAmount,
    required this.createdAt,
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
      createdAt: _toDateTime(json['created_at']),
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

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
