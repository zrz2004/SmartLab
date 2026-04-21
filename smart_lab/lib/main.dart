import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/alerts/presentation/bloc/alerts_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/chemicals/presentation/bloc/chemicals_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/environment/presentation/bloc/environment_bloc.dart';
import 'features/power/presentation/bloc/power_bloc.dart';
import 'features/security/presentation/bloc/security_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await configureDependencies();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

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
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider<DashboardBloc>(
          create: (_) => getIt<DashboardBloc>()..add(LoadDashboardData()),
        ),
        BlocProvider<EnvironmentBloc>(create: (_) => getIt<EnvironmentBloc>()),
        BlocProvider<PowerBloc>(create: (_) => getIt<PowerBloc>()),
        BlocProvider<SecurityBloc>(create: (_) => getIt<SecurityBloc>()),
        BlocProvider<ChemicalsBloc>(create: (_) => getIt<ChemicalsBloc>()),
        BlocProvider<AlertsBloc>(create: (_) => getIt<AlertsBloc>()),
      ],
      child: MaterialApp.router(
        title: 'SmartLab',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
