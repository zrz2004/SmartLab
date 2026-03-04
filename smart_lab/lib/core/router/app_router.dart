import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/main/presentation/pages/main_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/environment/presentation/pages/environment_page.dart';
import '../../features/power/presentation/pages/power_page.dart';
import '../../features/security/presentation/pages/security_page.dart';
import '../../features/chemicals/presentation/pages/chemicals_page.dart';
import '../../features/alerts/presentation/pages/alerts_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/lab_selection_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/device/presentation/pages/device_detail_page.dart';

/// 应用路由配置
/// 
/// 采用 GoRouter 实现声明式导航
/// 支持嵌套路由和路由守卫
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: true,
    
    routes: [
      // 登录页
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      
      // 实验室选择页
      GoRoute(
        path: '/select-lab',
        name: 'select-lab',
        builder: (context, state) => const LabSelectionPage(),
      ),
      
      // 主页面 (Shell Route - 带底部导航)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainPage(child: child),
        routes: [
          // 首页仪表盘
          GoRoute(
            path: '/',
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardPage(),
            ),
          ),
          
          // 环境监测
          GoRoute(
            path: '/environment',
            name: 'environment',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EnvironmentPage(),
            ),
          ),
          
          // 电源管理
          GoRoute(
            path: '/power',
            name: 'power',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PowerPage(),
            ),
          ),
          
          // 安防水路
          GoRoute(
            path: '/security',
            name: 'security',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SecurityPage(),
            ),
          ),
          
          // 危化品管理
          GoRoute(
            path: '/chemicals',
            name: 'chemicals',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChemicalsPage(),
            ),
          ),
        ],
      ),
      
      // 报警中心 (全屏页面)
      GoRoute(
        path: '/alerts',
        name: 'alerts',
        builder: (context, state) => const AlertsPage(),
      ),
      
      // 设备详情 (全屏页面)
      GoRoute(
        path: '/device/:deviceId',
        name: 'device-detail',
        builder: (context, state) {
          final deviceId = state.pathParameters['deviceId'] ?? '';
          return DeviceDetailPage(deviceId: deviceId);
        },
      ),
    ],
    
    // 错误页面
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              '页面未找到',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    ),
    
    // 路由重定向 (用于认证检查)
    redirect: (context, state) {
      // 获取当前认证状态
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final hasSelectedLab = authState.selectedLabId != null;
      final currentPath = state.matchedLocation;
      
      // 公开路由（不需要登录）
      final publicRoutes = ['/login'];
      final isPublicRoute = publicRoutes.contains(currentPath);
      
      // 如果正在检查认证状态，不进行重定向
      if (authState.status == AuthStatus.checking) {
        return null;
      }
      
      // 未认证用户，重定向到登录页
      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }
      
      // 已认证用户访问登录页，重定向到选择实验室或主页
      if (isAuthenticated && currentPath == '/login') {
        return hasSelectedLab ? '/' : '/select-lab';
      }
      
      // 已认证但未选择实验室，重定向到实验室选择页
      if (isAuthenticated && !hasSelectedLab && currentPath != '/select-lab') {
        return '/select-lab';
      }
      
      return null;
    },
  );
}
