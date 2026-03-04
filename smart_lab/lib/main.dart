import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/mqtt_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/environment/presentation/bloc/environment_bloc.dart';
import 'features/power/presentation/bloc/power_bloc.dart';
import 'features/security/presentation/bloc/security_bloc.dart';
import 'features/chemicals/presentation/bloc/chemicals_bloc.dart';
import 'features/alerts/presentation/bloc/alerts_bloc.dart';

/// 智慧实验室安全监测与预警系统
/// 
/// 基于物联网技术的实验室安全管理移动端应用
/// 采用 Clean Architecture + BLoC 状态管理
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Hive 本地存储
  await Hive.initFlutter();
  
  // 初始化依赖注入
  await configureDependencies();
  
  // 设置系统UI样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // 锁定竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const SmartLabApp());
}

class SmartLabApp extends StatelessWidget {
  const SmartLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 认证状态管理（全局单例，应用启动时检查登录状态）
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(AuthCheckRequested()),
        ),
        // 仪表盘状态管理
        BlocProvider<DashboardBloc>(
          create: (_) => getIt<DashboardBloc>()..add(LoadDashboardData()),
        ),
        // 环境监测状态管理
        BlocProvider<EnvironmentBloc>(
          create: (_) => getIt<EnvironmentBloc>(),
        ),
        // 电源管理状态管理
        BlocProvider<PowerBloc>(
          create: (_) => getIt<PowerBloc>(),
        ),
        // 安防水路状态管理
        BlocProvider<SecurityBloc>(
          create: (_) => getIt<SecurityBloc>(),
        ),
        // 危化品管理状态管理
        BlocProvider<ChemicalsBloc>(
          create: (_) => getIt<ChemicalsBloc>(),
        ),
        // 报警中心状态管理
        BlocProvider<AlertsBloc>(
          create: (_) => getIt<AlertsBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: '智慧实验室',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          // 全局错误边界和性能优化
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
