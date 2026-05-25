enum UserRole {
  customer,
  admin,
  unknown;

  static UserRole fromString(String? value) {
    switch (value) {
      case 'customer':
        return UserRole.customer;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.unknown;
    }
  }

  String get value {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.admin:
        return 'admin';
      case UserRole.unknown:
        return 'unknown';
    }
  }
}

class AppUser {
  final int id;
  final String authUserId;
  final String fullName;
  final String? username;
  final String email;
  final String? phone;
  final UserRole role;
  final String? avatarPath;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUser({
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

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: _toInt(json['id']),
      authUserId: json['auth_user_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      username: json['username']?.toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: UserRole.fromString(json['role']?.toString()),
      avatarPath: json['avatar_path']?.toString(),
      isActive: json['is_active'] == true,
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
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
