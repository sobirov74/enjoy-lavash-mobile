class UserRole {
  final String id;
  final String name;
  final List<String> permissionCodes;

  UserRole({
    required this.id,
    required this.name,
    required this.permissionCodes,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'],
      name: json['name'],
      permissionCodes: List<String>.from(json['permission_codes'] ?? []),
    );
  }
}

class User {
  final String id;
  final String? username;
  final bool? isAdmin;
  final List<String>? permissionCodes;
  final UserRole? role;

  User({
    required this.id,
    this.username,
    this.isAdmin,
    this.permissionCodes,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      isAdmin: json['is_admin'],
      permissionCodes: json['permission_codes'] != null
          ? List<String>.from(json['permission_codes'])
          : null,
      role: json['role'] != null ? UserRole.fromJson(json['role']) : null,
    );
  }
}
