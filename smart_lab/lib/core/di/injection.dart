import 'package:get_it/get_it.dart';

import '../localization/locale_cubit.dart';
import '../../features/alerts/presentation/bloc/alerts_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/chemicals/presentation/bloc/chemicals_bloc.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/environment/presentation/bloc/environment_bloc.dart';
import '../../features/power/presentation/bloc/power_bloc.dart';
import '../../features/security/presentation/bloc/security_bloc.dart';
import '../services/api_service.dart';
import '../services/evidence_service.dart';
import '../services/local_storage_service.dart';
import '../services/mqtt_service.dart';
import '../services/notification_service.dart';
import '../services/upload_reminder_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  getIt.registerLazySingleton<MqttService>(() => MqttService());

  final localStorageService = LocalStorageService();
  await localStorageService.initialize();
  getIt.registerLazySingleton<LocalStorageService>(() => localStorageService);

  final notificationService = NotificationService(
    localStorageService: localStorageService,
  );
  await notificationService.initialize();
  getIt.registerLazySingleton<NotificationService>(() => notificationService);

  getIt.registerLazySingleton<LocaleCubit>(
    () => LocaleCubit(storageService: localStorageService),
  );

  getIt.registerLazySingleton<UploadReminderService>(
    () => UploadReminderService(
      localStorageService: getIt<LocalStorageService>(),
      apiService: getIt<ApiService>(),
      notificationService: getIt<NotificationService>(),
    ),
  );

  getIt.registerLazySingleton<EvidenceService>(
    () => EvidenceService(
      apiService: getIt<ApiService>(),
      localStorageService: getIt<LocalStorageService>(),
      uploadReminderService: getIt<UploadReminderService>(),
    ),
  );

  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      apiService: getIt<ApiService>(),
      storageService: getIt<LocalStorageService>(),
    ),
  );

  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      mqttService: getIt<MqttService>(),
      apiService: getIt<ApiService>(),
      storageService: getIt<LocalStorageService>(),
    ),
  );

  getIt.registerFactory<EnvironmentBloc>(
    () => EnvironmentBloc(
      mqttService: getIt<MqttService>(),
    ),
  );

  getIt.registerFactory<PowerBloc>(
    () => PowerBloc(
      mqttService: getIt<MqttService>(),
      apiService: getIt<ApiService>(),
    ),
  );

  getIt.registerFactory<SecurityBloc>(
    () => SecurityBloc(
      mqttService: getIt<MqttService>(),
      apiService: getIt<ApiService>(),
    ),
  );

  getIt.registerFactory<ChemicalsBloc>(
    () => ChemicalsBloc(
      apiService: getIt<ApiService>(),
    ),
  );

  getIt.registerFactory<AlertsBloc>(
    () => AlertsBloc(
      mqttService: getIt<MqttService>(),
      apiService: getIt<ApiService>(),
    ),
  );
}
