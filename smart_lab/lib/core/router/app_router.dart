import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_localizations.dart';
import '../../features/alerts/presentation/pages/alerts_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/lab_selection_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/chemicals/presentation/pages/chemicals_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/device/presentation/pages/device_detail_page.dart';
import '../../features/environment/presentation/pages/environment_page.dart';
import '../../features/main/presentation/pages/main_page.dart';
import '../../features/power/presentation/pages/power_page.dart';
import '../../features/security/presentation/pages/security_page.dart';
import '../di/injection.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();
  static final _authRefresh = _GoRouterRefreshStream(getIt<AuthBloc>().stream);

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: _authRefresh,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/select-lab',
        name: 'select-lab',
        builder: (context, state) => const LabSelectionPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainPage(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(child: DashboardPage()),
          ),
          GoRoute(
            path: '/environment',
            name: 'environment',
            pageBuilder: (context, state) => const NoTransitionPage(child: EnvironmentPage()),
          ),
          GoRoute(
            path: '/power',
            name: 'power',
            pageBuilder: (context, state) => const NoTransitionPage(child: PowerPage()),
          ),
          GoRoute(
            path: '/security',
            name: 'security',
            pageBuilder: (context, state) => const NoTransitionPage(child: SecurityPage()),
          ),
          GoRoute(
            path: '/chemicals',
            name: 'chemicals',
            pageBuilder: (context, state) => const NoTransitionPage(child: ChemicalsPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/alerts',
        name: 'alerts',
        builder: (context, state) => const AlertsPage(),
      ),
      GoRoute(
        path: '/device/:deviceId',
        name: 'device-detail',
        builder: (context, state) {
          final deviceId = state.pathParameters['deviceId'] ?? '';
          return DeviceDetailPage(deviceId: deviceId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(context.l10n.t('router.pageNotFound'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
          ],
        ),
      ),
    ),
    redirect: (context, state) {
      final authState = getIt<AuthBloc>().state;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final hasSelectedLab = authState.currentLabId != null;
      final currentPath = state.matchedLocation;
      const publicRoutes = {'/login', '/register'};
      final isPublicRoute = publicRoutes.contains(currentPath);

      if (authState.status == AuthStatus.initial || authState.status == AuthStatus.checking) {
        return null;
      }
      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }
      if (isAuthenticated && (currentPath == '/login' || currentPath == '/register')) {
        return hasSelectedLab ? '/' : '/select-lab';
      }
      if (isAuthenticated && !hasSelectedLab && currentPath != '/select-lab') {
        return '/select-lab';
      }
      if (!isAuthenticated && currentPath == '/select-lab') {
        return '/login';
      }
      return null;
    },
  );
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
