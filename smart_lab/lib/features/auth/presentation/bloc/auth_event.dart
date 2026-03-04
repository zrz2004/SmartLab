part of 'auth_bloc.dart';

/// 认证事件基类
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

/// 检查认证状态
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// 登录请求
class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;
  final bool rememberMe;
  
  const AuthLoginRequested({
    required this.username,
    required this.password,
    this.rememberMe = false,
  });
  
  @override
  List<Object?> get props => [username, password, rememberMe];
}

/// 登出请求
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// 切换实验室
class AuthLabChanged extends AuthEvent {
  final String labId;
  
  const AuthLabChanged({required this.labId});
  
  @override
  List<Object?> get props => [labId];
}

/// Token 刷新请求
class AuthTokenRefreshRequested extends AuthEvent {
  const AuthTokenRefreshRequested();
}

/// 用户信息更新
class AuthUserUpdated extends AuthEvent {
  final Map<String, dynamic> updates;
  
  const AuthUserUpdated({required this.updates});
  
  @override
  List<Object?> get props => [updates];
}
