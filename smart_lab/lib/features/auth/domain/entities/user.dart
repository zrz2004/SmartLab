import 'package:equatable/equatable.dart';

/// 用户实体
/// 
/// 存储用户基本信息和权限数据
class User extends Equatable {
  final String id;
  final String username;         // 学号/工号
  final String name;             // 真实姓名
  final UserRole role;           // 用户角色
  final String? department;      // 院系
  final String? phone;           // 手机号
  final String? email;           // 邮箱
  final String? avatarUrl;       // 头像
  final List<String> accessibleLabIds;  // 可访问的实验室ID列表
  final DateTime? lastLoginAt;   // 最后登录时间
  final bool isActive;           // 账户是否激活
  
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
  
  /// 从 JSON 创建
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
      role: UserRole.fromString(json['role'] as String),
      department: json['department'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      accessibleLabIds: List<String>.from(json['accessible_lab_ids'] ?? []),
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
  
  /// 转换为 JSON
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
  
  /// 复制并修改
  User copyWith({
    String? id,
    String? username,
    String? name,
    UserRole? role,
    String? department,
    String? phone,
    String? email,
    String? avatarUrl,
    List<String>? accessibleLabIds,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      role: role ?? this.role,
      department: department ?? this.department,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      accessibleLabIds: accessibleLabIds ?? this.accessibleLabIds,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }
  
  /// 是否有指定实验室的访问权限
  bool hasAccessToLab(String labId) {
    if (role == UserRole.admin) return true;
    return accessibleLabIds.contains(labId);
  }
  
  /// 是否可以控制设备
  bool get canControlDevices => 
      role == UserRole.admin || 
      role == UserRole.teacher || 
      role == UserRole.graduate;
  
  /// 是否可以管理实验室
  bool get canManageLab =>
      role == UserRole.admin || role == UserRole.teacher;
  
  /// 是否可以确认报警
  bool get canAcknowledgeAlerts =>
      role != UserRole.undergraduate;
  
  /// 是否可以管理危化品
  bool canManageChemicals(String action) {
    if (action == 'view') return true;
    if (action == 'checkout') {
      return role == UserRole.admin || 
             role == UserRole.teacher ||
             role == UserRole.graduate;
    }
    if (action == 'checkin' || action == 'manage') {
      return role == UserRole.admin || role == UserRole.teacher;
    }
    return false;
  }
  
  @override
  List<Object?> get props => [
    id, 
    username, 
    name, 
    role, 
    accessibleLabIds,
    isActive,
  ];
}

/// 用户角色枚举
enum UserRole {
  admin,          // 系统管理员
  teacher,        // 教师/实验室负责人
  graduate,       // 研究生
  undergraduate;  // 本科生助理
  
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => UserRole.undergraduate,
    );
  }
  
  /// 显示名称
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return '系统管理员';
      case UserRole.teacher:
        return '教师';
      case UserRole.graduate:
        return '研究生';
      case UserRole.undergraduate:
        return '本科生助理';
    }
  }
  
  /// 权限等级 (用于比较)
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
  
  /// 是否可以管理指定角色的用户
  bool canManageRole(UserRole targetRole) {
    return level > targetRole.level;
  }
}
