class AdminDashboardModel {
  final AdminDashboardSummary summary;
  final List<AdminDashboardTopItem> topItems;
  final List<AdminDashboardRecentBooking> recentBookings;
  final List<AdminDashboardStatusCount> statusDistribution;

  const AdminDashboardModel({
    required this.summary,
    required this.topItems,
    required this.recentBookings,
    required this.statusDistribution,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final summaryRaw =
        data['summary'] ?? data['stats'] ?? data['dashboard_summary'] ?? data;

    final topItemsRaw =
        data['top_items'] ??
        data['topItems'] ??
        data['popular_items'] ??
        <dynamic>[];

    final recentBookingsRaw =
        data['recent_bookings'] ??
        data['recentBookings'] ??
        data['latest_bookings'] ??
        <dynamic>[];

    final statusRaw =
        data['booking_status_distribution'] ??
        data['status_distribution'] ??
        data['bookingStatusDistribution'] ??
        <dynamic>[];

    return AdminDashboardModel(
      summary: summaryRaw is Map<String, dynamic>
          ? AdminDashboardSummary.fromJson(summaryRaw)
          : const AdminDashboardSummary(),
      topItems: _toList(topItemsRaw)
          .whereType<Map<String, dynamic>>()
          .map(AdminDashboardTopItem.fromJson)
          .toList(),
      recentBookings: _toList(recentBookingsRaw)
          .whereType<Map<String, dynamic>>()
          .map(AdminDashboardRecentBooking.fromJson)
          .toList(),
      statusDistribution: AdminDashboardStatusCount.parseList(statusRaw),
    );
  }

  AdminDashboardModel copyWith({
    AdminDashboardSummary? summary,
    List<AdminDashboardTopItem>? topItems,
    List<AdminDashboardRecentBooking>? recentBookings,
    List<AdminDashboardStatusCount>? statusDistribution,
  }) {
    return AdminDashboardModel(
      summary: summary ?? this.summary,
      topItems: topItems ?? this.topItems,
      recentBookings: recentBookings ?? this.recentBookings,
      statusDistribution: statusDistribution ?? this.statusDistribution,
    );
  }

  static List<dynamic> _toList(Object? value) {
    if (value is List) return value;

    if (value is Map<String, dynamic>) {
      final nested =
          value['data'] ?? value['items'] ?? value['rows'] ?? value['results'];

      if (nested is List) return nested;
    }

    return <dynamic>[];
  }
}

class AdminDashboardSummary {
  final int totalUsers;
  final int totalItems;
  final int totalBookings;
  final int pendingVerifications;
  final int activeRentals;
  final int paymentPending;
  final num totalRevenue;

  const AdminDashboardSummary({
    this.totalUsers = 0,
    this.totalItems = 0,
    this.totalBookings = 0,
    this.pendingVerifications = 0,
    this.activeRentals = 0,
    this.paymentPending = 0,
    this.totalRevenue = 0,
  });

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    return AdminDashboardSummary(
      totalUsers: _toInt(
        json['total_users'] ??
            json['totalUsers'] ??
            json['users_count'] ??
            json['total_customers'],
      ),
      totalItems: _toInt(
        json['total_items'] ??
            json['totalItems'] ??
            json['items_count'] ??
            json['total_products'],
      ),
      totalBookings: _toInt(
        json['total_bookings'] ??
            json['totalBookings'] ??
            json['bookings_count'],
      ),
      pendingVerifications: _toInt(
        json['pending_verifications'] ??
            json['pendingVerifications'] ??
            json['pending_identity_verifications'] ??
            json['pending_ktp'] ??
            json['total_pending_verifications'],
      ),
      activeRentals: _toInt(
        json['active_rentals'] ??
            json['activeRentals'] ??
            json['ongoing_bookings'] ??
            json['active_bookings'],
      ),
      paymentPending: _toInt(
        json['payment_pending'] ??
            json['paymentPending'] ??
            json['pending_payments'] ??
            json['total_pending_payments'],
      ),
      totalRevenue: _toNum(
        json['total_revenue'] ??
            json['totalRevenue'] ??
            json['revenue'] ??
            json['income'] ??
            json['gross_revenue'],
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

class AdminDashboardTopItem {
  final int id;
  final String name;
  final String brand;
  final int totalBookings;
  final num totalRevenue;

  const AdminDashboardTopItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.totalBookings,
    required this.totalRevenue,
  });

  factory AdminDashboardTopItem.fromJson(Map<String, dynamic> json) {
    final item = json['item'];

    final itemSource = item is Map<String, dynamic>
        ? item
        : <String, dynamic>{};

    return AdminDashboardTopItem(
      id: _toInt(json['item_id'] ?? json['id'] ?? itemSource['id']),
      name:
          json['item_name']?.toString() ??
          json['name']?.toString() ??
          itemSource['name']?.toString() ??
          'Barang',
      brand:
          json['brand']?.toString() ?? itemSource['brand']?.toString() ?? '-',
      totalBookings: _toInt(
        json['total_bookings'] ??
            json['booking_count'] ??
            json['total_rentals'] ??
            json['count'],
      ),
      totalRevenue: _toNum(
        json['total_revenue'] ?? json['revenue'] ?? json['total_amount'],
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

class AdminDashboardRecentBooking {
  final int id;
  final String code;
  final String customerName;
  final String status;
  final num totalAmount;
  final DateTime? createdAt;

  const AdminDashboardRecentBooking({
    required this.id,
    required this.code,
    required this.customerName,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
  });

  factory AdminDashboardRecentBooking.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] ?? json['user'];
    final customerSource = customer is Map<String, dynamic>
        ? customer
        : <String, dynamic>{};

    return AdminDashboardRecentBooking(
      id: _toInt(json['id']),
      code:
          json['booking_code']?.toString() ??
          json['code']?.toString() ??
          'BOOK-${_toInt(json['id'])}',
      customerName:
          customerSource['full_name']?.toString() ??
          json['customer_name']?.toString() ??
          'Customer',
      status: json['status']?.toString() ?? '-',
      totalAmount: _toNum(
        json['total_amount'] ?? json['amount'] ?? json['grand_total'],
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

class AdminDashboardStatusCount {
  final String status;
  final int count;

  const AdminDashboardStatusCount({required this.status, required this.count});

  factory AdminDashboardStatusCount.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStatusCount(
      status:
          json['status']?.toString() ??
          json['booking_status']?.toString() ??
          '-',
      count: _toInt(json['count'] ?? json['total'] ?? json['value']),
    );
  }

  static List<AdminDashboardStatusCount> parseList(Object? raw) {
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(AdminDashboardStatusCount.fromJson)
          .toList();
    }

    if (raw is Map<String, dynamic>) {
      return raw.entries
          .map(
            (entry) => AdminDashboardStatusCount(
              status: entry.key,
              count: _toInt(entry.value),
            ),
          )
          .toList();
    }

    return <AdminDashboardStatusCount>[];
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
