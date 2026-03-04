import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../services/mqtt_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/local_storage_service.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/environment/presentation/bloc/environment_bloc.dart';
import '../../features/power/presentation/bloc/power_bloc.dart';
import '../../features/security/presentation/bloc/security_bloc.dart';
import '../../features/chemicals/presentation/bloc/chemicals_bloc.dart';
import '../../features/alerts/presentation/bloc/alerts_bloc.dart';

final getIt = GetIt.instance;

/// 配置依赖注入
/// 
/// 采用分层架构:
/// - Services: 底层服务（网络、存储、通知）
/// - Repositories: 数据仓库
/// - UseCases: 业务用例
/// - BLoCs: 状态管理
Future<void> configureDependencies() async {
  // ==================== 服务层 ====================
  
  // API 服务
  getIt.registerLazySingleton<ApiService>(
    () => ApiService(),
  );
  
  // MQTT 服务
  getIt.registerLazySingleton<MqttService>(
    () => MqttService(),
  );
  
  // 本地存储服务
  final localStorageService = LocalStorageService();
  await localStorageService.initialize();
  getIt.registerLazySingleton<LocalStorageService>(
    () => localStorageService,
  );
  
  // 通知服务
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(),
  );
  
  // ==================== 状态管理层 ====================
  
  // 认证 BLoC (单例，全局共享)
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      apiService: getIt<ApiService>(),
      storageService: getIt<LocalStorageService>(),
    ),
  );
  
  // 仪表盘 BLoC
  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      mqttService: getIt<MqttService>(),
      apiService: getIt<ApiService>(),
    ),
  );
  
  // 环境监测 BLoC
  getIt.registerFactory<EnvironmentBloc>(
    () => EnvironmentBloc(
      mqttService: getIt<MqttService>(),
    ),
  );
  
  // 电源管理 BLoC
  getIt.registerFactory<PowerBloc>(
    () => PowerBloc(
      mqttService: getIt<MqttService>(),
      apiService: getIt<ApiService>(),
    ),
  );
  
  // 安防水路 BLoC
  getIt.registerFactory<SecurityBloc>(
    () => SecurityBloc(
      mqttService: getIt<MqttService>(),
      apiService: getIt<ApiService>(),
    ),
  );
  
  // 危化品管理 BLoC
  getIt.registerFactory<ChemicalsBloc>(
    () => ChemicalsBloc(
      apiService: getIt<ApiService>(),
    ),
  );
  
  // 报警中心 BLoC
  getIt.registerFactory<AlertsBloc>(
    () => AlertsBloc(
      mqttService: getIt<MqttService>(),
      apiService: getIt<ApiService>(),
    ),
  );
}
