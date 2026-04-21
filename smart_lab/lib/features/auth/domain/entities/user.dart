import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String name;
  final UserRole role;
  final String? department;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final List<String> accessibleLabIds;
  final DateTime? lastLoginAt;
  final bool isActive;

  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.department,
    this.phone,
    this.email,
    this.avatarUrl,
    this.accessibleLabIds = const [],
    this.lastLoginAt,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      username: json['username'] as String,
      name: json['name'] as String,
      role: UserRole.fromString(json['role'] as String),
      department: json['department'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      accessibleLabIds: List<String>.from(json['accessible_lab_ids'] ?? const <String>[]),
      lastLoginAt: json['last_login_at'] != null ? DateTime.parse(json['last_login_at'] as String) : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'role': role.name,
      'department': department,
      'phone': phone,
      'email': email,
      'avatar_url': avatarUrl,
      'accessible_lab_ids': accessibleLabIds,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  bool hasAccessToLab(String labId) {
    if (role == UserRole.admin) return true;
    return accessibleLabIds.contains(labId);
  }

  bool get canControlDevices => role == UserRole.admin || role == UserRole.teacher || role == UserRole.graduate;
  bool get canManageLab => role == UserRole.admin || role == UserRole.teacher;
  bool get canAcknowledgeAlerts => role != UserRole.undergraduate;
  String get roleDisplayName => role.displayName;

  bool canManageChemicals(String action) {
    if (action == 'view') return true;
    if (action == 'checkout') return role == UserRole.admin || role == UserRole.teacher || role == UserRole.graduate;
    if (action == 'checkin' || action == 'manage') return role == UserRole.admin || role == UserRole.teacher;
    return false;
  }

  @override
  List<Object?> get props => [id, username, name, role, accessibleLabIds, isActive];
}

enum UserRole {
  admin,
  teacher,
  graduate,
  undergraduate;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => UserRole.undergraduate,
    );
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.graduate:
        return 'Graduate';
      case UserRole.undergraduate:
        return 'Assistant';
    }
  }

  int get level {
    switch (this) {
      case UserRole.admin:
        return 100;
      case UserRole.teacher:
        return 80;
      case UserRole.graduate:
        return 60;
      case UserRole.undergraduate:
        return 40;
    }
  }

  bool canManageRole(UserRole targetRole) => level > targetRole.level;
}
