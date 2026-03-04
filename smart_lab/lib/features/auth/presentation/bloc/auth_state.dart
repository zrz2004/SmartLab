part of 'auth_bloc.dart';

/// 认证状态枚举
enum AuthStatus {
  initial,        // 初始状态
  loading,        // 加载中
  authenticated,  // 已认证
  unauthenticated, // 未认证
  error,          // 错误
}

/// 认证状态
class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final List<LabInfo> accessibleLabs;
  final String? currentLabId;
  final String? errorMessage;
  
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.accessibleLabs = const [],
    this.currentLabId,
    this.errorMessage,
  });
  
  /// 是否已登录
  bool get isLoggedIn => status == AuthStatus.authenticated && user != null;
  
  /// 是否正在加载
  bool get isLoading => status == AuthStatus.loading;
  
  /// 当前实验室信息
  LabInfo? get currentLab {
    if (currentLabId == null) return null;
    try {
      return accessibleLabs.firstWhere((lab) => lab.id == currentLabId);
    } catch (_) {
      return null;
    }
  }
  
  /// 是否可以控制设备
  bool get canControlDevices => 
      user != null && user!.canControlDevices;
  
  /// 是否可以管理实验室
  bool get canManageLab =>
      user != null && user!.canManageLab;
  
  /// 是否可以确认报警
  bool get canAcknowledgeAlerts =>
      user != null && user!.canAcknowledgeAlerts;
  
  /// 检查是否有指定实验室的访问权限
  bool hasLabAccess(String labId) {
    if (user == null) return false;
    return user!.hasAccessToLab(labId);
  }
  
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    List<LabInfo>? accessibleLabs,
    String? currentLabId,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      accessibleLabs: accessibleLabs ?? this.accessibleLabs,
      currentLabId: currentLabId ?? this.currentLabId,
      errorMessage: errorMessage,
    );
  }
  
  @override
  List<Object?> get props => [
    status,
    user,
    accessibleLabs,
    currentLabId,
    errorMessage,
  ];
}
