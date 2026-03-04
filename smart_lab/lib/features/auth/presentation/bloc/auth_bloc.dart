import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/constants/lab_config.dart';
import '../../../../core/constants/mock_data_provider.dart';
import '../../domain/entities/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// 认证 BLoC
/// 
/// 管理用户认证状态
/// - 登录/登出
/// - Token 管理
/// - 实验室切换
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;
  final LocalStorageService storageService;
  
  AuthBloc({
    required this.apiService,
    required this.storageService,
  }) : super(const AuthState()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthLabChanged>(_onAuthLabChanged);
  }
  
  /// 检查认证状态
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    try {
      // 检查本地是否有存储的 Token
      final accessToken = await storageService.getAccessToken();
      
      if (accessToken == null) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
        return;
      }
      
      // TODO: 验证 Token 有效性，获取用户信息
      // 目前使用模拟数据
      final savedLabId = storageService.getCurrentLabId();
      final mockUser = _getMockUser();
      
      // 设置 API Token
      final refreshToken = await storageService.getRefreshToken();
      if (refreshToken != null) {
        apiService.setTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }
      
      // 更新 MockDataProvider 的当前实验室
      if (savedLabId != null) {
        MockDataProvider.setCurrentLab(savedLabId);
      }
      
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: mockUser,
        accessibleLabs: _getAccessibleLabs(mockUser),
        currentLabId: savedLabId ?? LabConfig.defaultLab.id,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      ));
    }
  }
  
  /// 登录
  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    try {
      // 调用登录 API
      final response = await apiService.login(
        username: event.username,
        password: event.password,
      );
      
      // 保存 Token
      await storageService.saveTokens(
        accessToken: response['access_token'] as String,
        refreshToken: response['refresh_token'] as String,
      );
      
      // 解析用户信息
      final user = User.fromJson(response['user'] as Map<String, dynamic>);
      
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        accessibleLabs: _getAccessibleLabs(user),
        currentLabId: LabConfig.defaultLab.id,
      ));
    } catch (e) {
      // API 调用失败，使用模拟登录
      if (_mockLogin(event.username, event.password)) {
        final mockUser = _getMockUser(username: event.username);
        
        // 保存模拟 Token
        await storageService.saveTokens(
          accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
          refreshToken: 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: mockUser,
          accessibleLabs: _getAccessibleLabs(mockUser),
          currentLabId: LabConfig.defaultLab.id,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: '用户名或密码错误',
        ));
      }
    }
  }
  
  /// 登出
  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await apiService.logout();
    } catch (_) {
      // 忽略登出 API 错误
    }
    
    // 清除本地 Token
    await storageService.clearTokens();
    
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
  
  /// 切换实验室
  Future<void> _onAuthLabChanged(
    AuthLabChanged event,
    Emitter<AuthState> emit,
  ) async {
    // 验证用户是否有权限访问该实验室
    if (state.user != null && !state.user!.hasAccessToLab(event.labId)) {
      emit(state.copyWith(errorMessage: '您没有访问该实验室的权限'));
      return;
    }
    
    // 保存选择
    await storageService.setCurrentLabId(event.labId);
    
    // 更新 MockDataProvider
    MockDataProvider.setCurrentLab(event.labId);
    
    emit(state.copyWith(currentLabId: event.labId));
  }
  
  /// 模拟登录验证
  bool _mockLogin(String username, String password) {
    // 测试账号
    final testAccounts = {
      'admin': 'admin123',
      'teacher': 'teacher123',
      'graduate': 'graduate123',
      'student': 'student123',
      // 按学号格式
      '2021001': 'password123',
      '2022001': 'password123',
    };
    
    return testAccounts[username] == password;
  }
  
  /// 获取模拟用户
  User _getMockUser({String? username}) {
    final role = _getRoleFromUsername(username ?? 'admin');
    
    return User(
      id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
      username: username ?? 'admin',
      name: _getNameFromRole(role),
      role: role,
      department: '信息科学与技术学院',
      accessibleLabIds: role == UserRole.admin 
          ? LabConfig.labs.map((l) => l.id).toList()
          : [LabConfig.defaultLab.id],
      lastLoginAt: DateTime.now(),
      isActive: true,
    );
  }
  
  UserRole _getRoleFromUsername(String username) {
    if (username == 'admin') return UserRole.admin;
    if (username == 'teacher') return UserRole.teacher;
    if (username == 'graduate') return UserRole.graduate;
    if (username.startsWith('202')) return UserRole.graduate;
    return UserRole.undergraduate;
  }
  
  String _getNameFromRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '系统管理员';
      case UserRole.teacher:
        return '王老师';
      case UserRole.graduate:
        return '张三';
      case UserRole.undergraduate:
        return '李四';
    }
  }
  
  /// 获取用户可访问的实验室列表
  List<LabInfo> _getAccessibleLabs(User user) {
    if (user.role == UserRole.admin) {
      return LabConfig.labs;
    }
    return LabConfig.labs
        .where((lab) => user.accessibleLabIds.contains(lab.id))
        .toList();
  }
}
