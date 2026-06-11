class AdminUserModel {
  final int id;
  final String authUserId;
  final String fullName;
  final String username;
  final String email;
  final String phone;
  final String role;
  final String? avatarPath;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminUserModel({
    required this.id,
    required this.authUserId,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    required this.avatarPath,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: _toInt(json['id']),
      authUserId: json['auth_user_id']?.toString() ?? '',
      fullName:
          json['full_name']?.toString() ?? json['name']?.toString() ?? 'User',
      username: json['username']?.toString() ?? '-',
      email: json['email']?.toString() ?? '-',
      phone: json['phone']?.toString() ?? '-',
      role: json['role']?.toString() ?? 'customer',
      avatarPath: json['avatar_path']?.toString(),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  bool get isAdmin => role == 'admin';

  bool get isCustomer => role == 'customer';

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
