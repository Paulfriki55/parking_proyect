enum UserRole {
  agent,
  supervisor,
  administrator,
}

class User {
  final int? id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      role: UserRole.values.firstWhere((e) => e.name == map['role']),
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  bool canManageHouses() {
    return role == UserRole.administrator || role == UserRole.supervisor;
  }

  bool canViewReports() {
    return role == UserRole.administrator || role == UserRole.supervisor;
  }

  bool canManageUsers() {
    return role == UserRole.administrator;
  }
}
