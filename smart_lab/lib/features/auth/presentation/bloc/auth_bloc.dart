import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/lab_config.dart';
import '../../../../core/constants/mock_data_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/entities/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;
  final LocalStorageService storageService;

  AuthBloc({
    required this.apiService,
    required this.storageService,
  }) : super(const AuthState()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthLabChanged>(_onAuthLabChanged);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.checking, errorMessage: null));

    try {
      final accessToken = await storageService.getAccessToken();
      if (accessToken == null) {
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearUser: true,
            clearCurrentLabId: true,
            accessibleLabs: const [],
          ),
        );
        return;
      }

      final refreshToken = await storageService.getRefreshToken();
      if (refreshToken != null) {
        apiService.setTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      final savedLabId = storageService.getCurrentLabId();
      User user;
      try {
        user = User.fromJson(await apiService.getCurrentUser());
      } catch (_) {
        user = _getMockUser();
      }

      final accessibleLabs = _getAccessibleLabs(user);
      final currentLabId = _resolveCurrentLabId(savedLabId, accessibleLabs);
      if (currentLabId != null) {
        MockDataProvider.setCurrentLab(currentLabId);
      } else {
        await storageService.clearCurrentLabId();
      }

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          accessibleLabs: accessibleLabs,
          currentLabId: currentLabId,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          clearCurrentLabId: true,
          accessibleLabs: const [],
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      final response = await apiService.login(
        username: event.username,
        password: event.password,
      );

      await storageService.saveTokens(
        accessToken: response['access_token'] as String,
        refreshToken: response['refresh_token'] as String,
      );

      final user = User.fromJson(response['user'] as Map<String, dynamic>);
      final accessibleLabs = _getAccessibleLabs(user);
      final currentLabId = _resolveCurrentLabId(
        storageService.getCurrentLabId(),
        accessibleLabs,
      );

      if (currentLabId != null) {
        await storageService.setCurrentLabId(currentLabId);
        MockDataProvider.setCurrentLab(currentLabId);
      } else {
        await storageService.clearCurrentLabId();
      }

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          accessibleLabs: accessibleLabs,
          currentLabId: currentLabId,
          errorMessage: null,
        ),
      );
    } catch (_) {
      if (_mockLogin(event.username, event.password)) {
        final mockUser = _getMockUser(username: event.username);
        final accessibleLabs = _getAccessibleLabs(mockUser);
        final currentLabId = _resolveCurrentLabId(
          storageService.getCurrentLabId(),
          accessibleLabs,
        );

        await storageService.saveTokens(
          accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
          refreshToken:
              'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (currentLabId != null) {
          await storageService.setCurrentLabId(currentLabId);
          MockDataProvider.setCurrentLab(currentLabId);
        } else {
          await storageService.clearCurrentLabId();
        }

        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: mockUser,
            accessibleLabs: accessibleLabs,
            currentLabId: currentLabId,
            errorMessage: null,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: '用户名或密码错误',
        ),
      );
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      await apiService.registerUser(
        username: event.username,
        password: event.password,
        name: event.name,
        email: event.email,
        phone: event.phone,
        requestedRole: event.requestedRole.name,
      );

      emit(
        state.copyWith(
          status: AuthStatus.registrationPending,
          errorMessage: 'Registration request submitted and waiting for review.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.registrationPending,
          errorMessage: 'Registration request stored as pending review.',
        ),
      );
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await apiService.logout();
    } catch (_) {
      // ignore logout errors
    }

    await storageService.clearTokens();
    await storageService.clearCurrentLabId();

    emit(
      const AuthState(
        status: AuthStatus.unauthenticated,
        accessibleLabs: [],
      ),
    );
  }

  Future<void> _onAuthLabChanged(
    AuthLabChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (state.user != null && !state.user!.hasAccessToLab(event.labId)) {
      emit(state.copyWith(errorMessage: '您没有访问该实验室的权限'));
      return;
    }

    try {
      await apiService.selectLab(event.labId);
    } catch (_) {
      // Keep mock/dev fallback available.
    }

    await storageService.setCurrentLabId(event.labId);
    MockDataProvider.setCurrentLab(event.labId);

    emit(state.copyWith(currentLabId: event.labId, errorMessage: null));
  }

  String? _resolveCurrentLabId(String? savedLabId, List<LabInfo> labs) {
    final accessibleIds = labs.map((lab) => lab.id).toSet();
    if (savedLabId != null && accessibleIds.contains(savedLabId)) {
      return savedLabId;
    }
    if (labs.length == 1) {
      return labs.first.id;
    }
    return null;
  }

  bool _mockLogin(String username, String password) {
    final testAccounts = {
      'admin': 'admin123',
      'teacher': 'teacher123',
      'graduate': 'graduate123',
      'student': 'student123',
      '2021001': 'password123',
      '2022001': 'password123',
    };

    return testAccounts[username] == password;
  }

  User _getMockUser({String? username}) {
    final role = _getRoleFromUsername(username ?? 'admin');

    return User(
      id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
      username: username ?? 'admin',
      name: _getNameFromRole(role),
      role: role,
      department: 'School of Information Science',
      accessibleLabIds: role == UserRole.admin
          ? LabConfig.labs.map((lab) => lab.id).toList()
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
        return 'Admin';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.graduate:
        return 'Graduate';
      case UserRole.undergraduate:
        return 'Assistant';
    }
  }

  List<LabInfo> _getAccessibleLabs(User user) {
    if (user.role == UserRole.admin) {
      return LabConfig.labs;
    }

    final labs = LabConfig.labs
        .where((lab) => user.accessibleLabIds.contains(lab.id))
        .toList();

    return labs.isEmpty ? [LabConfig.defaultLab] : labs;
  }
}
