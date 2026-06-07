class PaymentModel {
  final int id;
  final int bookingId;
  final String provider;
  final String externalOrderId;
  final String? transactionId;
  final String? snapToken;
  final String? redirectUrl;
  final num grossAmount;
  final String? paymentType;
  final String status;
  final String? fraudStatus;
  final DateTime? paidAt;
  final DateTime? expiredAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.provider,
    required this.externalOrderId,
    required this.transactionId,
    required this.snapToken,
    required this.redirectUrl,
    required this.grossAmount,
    required this.paymentType,
    required this.status,
    required this.fraudStatus,
    required this.paidAt,
    required this.expiredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: _toInt(json['id']),
      bookingId: _toInt(json['booking_id']),
      provider: json['provider']?.toString() ?? '-',
      externalOrderId: json['external_order_id']?.toString() ?? '-',
      transactionId: json['transaction_id']?.toString(),
      snapToken: json['snap_token']?.toString(),
      redirectUrl:
          json['redirect_url']?.toString() ??
          _redirectUrlFromRawResponse(json['raw_response']),
      grossAmount: _toNum(json['gross_amount']),
      paymentType: json['payment_type']?.toString(),
      status: json['status']?.toString() ?? '-',
      fraudStatus: json['fraud_status']?.toString(),
      paidAt: _toDateTime(json['paid_at']),
      expiredAt: _toDateTime(json['expired_at']),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  bool get isPaid {
    return status == 'paid' ||
        status == 'settlement' ||
        status == 'capture' ||
        paidAt != null;
  }

  bool get canOpenPayment {
    return redirectUrl != null && redirectUrl!.trim().isNotEmpty && !isPaid;
  }

  static String? _redirectUrlFromRawResponse(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw['redirect_url']?.toString();
    }

    return null;
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
