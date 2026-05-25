class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Meta? meta;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromData,
  ) {
    return ApiResponse<T>(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json.containsKey('data') ? fromData(json['data']) : null,
      meta: json['meta'] is Map<String, dynamic>
          ? Meta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Meta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const Meta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      page: _toInt(json['page']),
      limit: _toInt(json['limit']),
      total: _toInt(json['total']),
      totalPages: _toInt(json['total_pages']),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}