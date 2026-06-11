class NotificationModel {
  final int id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? 'Notifikasi',
      body: json['body']?.toString() ?? json['message']?.toString() ?? '',
      data: _toMap(json['data']),
      isRead: json['is_read'] is bool ? json['is_read'] as bool : false,
      createdAt: _toDateTime(json['created_at']),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  static Map<String, dynamic> _toMap(Object? value) {
    if (value is Map<String, dynamic>) return value;

    return <String, dynamic>{};
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
