class ProfileModel {
  final int id;
  final String authUserId;
  final String fullName;
  final String? username;
  final String email;
  final String? phone;
  final String role;
  final String? avatarPath;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
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

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: _toInt(json['id']),
      authUserId: json['auth_user_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '-',
      username: json['username']?.toString(),
      email: json['email']?.toString() ?? '-',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'customer',
      avatarPath: json['avatar_path']?.toString(),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  ProfileModel copyWith({String? fullName, String? phone, String? avatarPath}) {
    return ProfileModel(
      id: id,
      authUserId: authUserId,
      fullName: fullName ?? this.fullName,
      username: username,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      avatarPath: avatarPath ?? this.avatarPath,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
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
