enum UserRole { admin, manager, seller }

class UserModel {
  final int? id;
  final String uuid;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final bool isActive;
  final String? token;
  final DateTime? lastLogin;

  UserModel({
    this.id,
    required this.uuid,
    required this.name,
    required this.email,
    this.phone,
    this.role = UserRole.seller,
    this.isActive = true,
    this.token,
    this.lastLogin,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isManager => role == UserRole.manager || role == UserRole.admin;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'uuid': uuid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'is_active': isActive ? 1 : 0,
      'token': token,
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    UserRole userRole = UserRole.seller;
    try {
      userRole = UserRole.values.byName(map['role']?.toString().toLowerCase() ?? 'seller');
    } catch (_) {
      userRole = UserRole.seller;
    }

    return UserModel(
      id: map['id'] as int?,
      uuid: map['uuid']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Staff',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString(),
      role: userRole,
      isActive: (map['is_active'] == 1 || map['is_active'] == true || map['is_active'] == null),
      token: map['token']?.toString(),
      lastLogin: map['last_login'] != null ? DateTime.tryParse(map['last_login'].toString()) : null,
    );
  }
}
