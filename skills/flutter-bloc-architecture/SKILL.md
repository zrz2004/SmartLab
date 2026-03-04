---
name: flutter-bloc-architecture
description: Flutter BLoC 状态管理架构规范。涵盖 BLoC 模式实现、事件/状态设计、Clean Architecture 集成、测试策略等方面。适用于构建可维护、可测试的 Flutter 应用。
license: MIT
metadata:
  author: SmartLab Team
  version: "1.0.0"
  package: flutter_bloc ^8.0.0
  patterns: ["BLoC", "Clean Architecture", "Repository Pattern"]
---

# Flutter BLoC 架构规范

基于 BLoC (Business Logic Component) 模式的 Flutter 应用架构指南，结合 Clean Architecture 原则，适用于智慧实验室安全监测与预警系统。

## 适用场景

在以下情况下参考本指南：
- 创建新的功能模块
- 实现复杂的状态管理逻辑
- 设计事件驱动的业务流程
- 编写 BLoC 相关的单元测试
- 重构现有状态管理代码

## 架构概览

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Presentation Layer                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                │
│  │   Widgets   │  │    BLoC     │  │   States    │                │
│  │   (Views)   │←─│  (Logic)    │──│   Events    │                │
│  └─────────────┘  └──────┬──────┘  └─────────────┘                │
└──────────────────────────┼──────────────────────────────────────────┘
                           │
┌──────────────────────────┼──────────────────────────────────────────┐
│                     Domain Layer                                    │
│  ┌─────────────┐  ┌──────▼──────┐  ┌─────────────┐                │
│  │  Entities   │  │  Use Cases  │  │ Repositories│                │
│  │  (Models)   │  │  (Actions)  │──│ (Interfaces)│                │
│  └─────────────┘  └─────────────┘  └─────────────┘                │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
┌──────────────────────────┼──────────────────────────────────────────┐
│                      Data Layer                                     │
│  ┌─────────────┐  ┌──────▼──────┐  ┌─────────────┐                │
│  │   Models    │  │ Repositories│  │ DataSources │                │
│  │   (DTOs)    │  │   (Impl)    │──│(Remote/Local)│               │
│  └─────────────┘  └─────────────┘  └─────────────┘                │
└─────────────────────────────────────────────────────────────────────┘
```

## 目录结构规范

```
lib/
├── core/                           # 核心通用代码
│   ├── error/                      # 错误处理
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── usecases/                   # UseCase 基类
│   │   └── usecase.dart
│   └── utils/                      # 工具类
│       └── input_converter.dart
│
├── features/                       # 功能模块
│   └── safety_monitoring/          # 安全监测模块
│       ├── data/                   # 数据层
│       │   ├── datasources/
│       │   │   ├── safety_remote_datasource.dart
│       │   │   └── safety_local_datasource.dart
│       │   ├── models/
│       │   │   └── sensor_reading_model.dart
│       │   └── repositories/
│       │       └── safety_repository_impl.dart
│       │
│       ├── domain/                 # 领域层
│       │   ├── entities/
│       │   │   └── sensor_reading.dart
│       │   ├── repositories/
│       │   │   └── safety_repository.dart
│       │   └── usecases/
│       │       ├── get_sensor_readings.dart
│       │       └── subscribe_to_alerts.dart
│       │
│       └── presentation/           # 表现层
│           ├── bloc/
│           │   ├── safety_bloc.dart
│           │   ├── safety_event.dart
│           │   └── safety_state.dart
│           ├── pages/
│           │   └── safety_monitoring_page.dart
│           └── widgets/
│               └── sensor_reading_card.dart
│
└── injection_container.dart        # 依赖注入
```

## BLoC 实现规范

### Event 设计
```dart
// safety_event.dart
part of 'safety_bloc.dart';

/// 所有事件的基类
sealed class SafetyEvent extends Equatable {
  const SafetyEvent();
  
  @override
  List<Object?> get props => [];
}

/// 加载传感器数据事件
final class LoadSensorData extends SafetyEvent {
  const LoadSensorData();
}

/// 筛选传感器类型事件
final class FilterBySensorType extends SafetyEvent {
  final SensorType? type;
  
  const FilterBySensorType(this.type);
  
  @override
  List<Object?> get props => [type];
}

/// 订阅实时警报事件
final class SubscribeToAlerts extends SafetyEvent {
  const SubscribeToAlerts();
}

/// 确认警报事件
final class AcknowledgeAlert extends SafetyEvent {
  final String alertId;
  final String userId;
  
  const AcknowledgeAlert({
    required this.alertId,
    required this.userId,
  });
  
  @override
  List<Object?> get props => [alertId, userId];
}

/// 刷新数据事件
final class RefreshData extends SafetyEvent {
  const RefreshData();
}
```

### State 设计
```dart
// safety_state.dart
part of 'safety_bloc.dart';

/// 状态基类 - 使用 sealed class 确保穷举
sealed class SafetyState extends Equatable {
  const SafetyState();
  
  @override
  List<Object?> get props => [];
}

/// 初始状态
final class SafetyInitial extends SafetyState {
  const SafetyInitial();
}

/// 加载中状态
final class SafetyLoading extends SafetyState {
  const SafetyLoading();
}

/// 加载成功状态
final class SafetyLoaded extends SafetyState {
  final List<SensorReading> readings;
  final List<Alert> alerts;
  final SensorType? selectedType;
  final DateTime lastUpdated;
  
  const SafetyLoaded({
    required this.readings,
    required this.alerts,
    this.selectedType,
    required this.lastUpdated,
  });
  
  /// 使用 copyWith 更新状态
  SafetyLoaded copyWith({
    List<SensorReading>? readings,
    List<Alert>? alerts,
    SensorType? selectedType,
    DateTime? lastUpdated,
  }) {
    return SafetyLoaded(
      readings: readings ?? this.readings,
      alerts: alerts ?? this.alerts,
      selectedType: selectedType ?? this.selectedType,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  @override
  List<Object?> get props => [readings, alerts, selectedType, lastUpdated];
}

/// 错误状态
final class SafetyError extends SafetyState {
  final String message;
  final SafetyState? previousState;  // 保留之前的状态以便恢复
  
  const SafetyError({
    required this.message,
    this.previousState,
  });
  
  @override
  List<Object?> get props => [message, previousState];
}
```

### BLoC 实现
```dart
// safety_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'safety_event.dart';
part 'safety_state.dart';

class SafetyBloc extends Bloc<SafetyEvent, SafetyState> {
  final GetSensorReadings _getSensorReadings;
  final SubscribeToAlerts _subscribeToAlerts;
  final AcknowledgeAlertUseCase _acknowledgeAlert;
  
  StreamSubscription<Alert>? _alertSubscription;
  
  SafetyBloc({
    required GetSensorReadings getSensorReadings,
    required SubscribeToAlerts subscribeToAlerts,
    required AcknowledgeAlertUseCase acknowledgeAlert,
  })  : _getSensorReadings = getSensorReadings,
        _subscribeToAlerts = subscribeToAlerts,
        _acknowledgeAlert = acknowledgeAlert,
        super(const SafetyInitial()) {
    // 注册事件处理器
    on<LoadSensorData>(_onLoadSensorData);
    on<FilterBySensorType>(_onFilterBySensorType);
    on<SubscribeToAlerts>(_onSubscribeToAlerts);
    on<AcknowledgeAlert>(_onAcknowledgeAlert);
    on<RefreshData>(_onRefreshData);
    on<_AlertReceived>(_onAlertReceived);
  }
  
  /// 加载传感器数据
  Future<void> _onLoadSensorData(
    LoadSensorData event,
    Emitter<SafetyState> emit,
  ) async {
    emit(const SafetyLoading());
    
    final result = await _getSensorReadings(NoParams());
    
    result.fold(
      (failure) => emit(SafetyError(message: failure.message)),
      (readings) => emit(SafetyLoaded(
        readings: readings,
        alerts: const [],
        lastUpdated: DateTime.now(),
      )),
    );
  }
  
  /// 筛选传感器类型
  Future<void> _onFilterBySensorType(
    FilterBySensorType event,
    Emitter<SafetyState> emit,
  ) async {
    final currentState = state;
    if (currentState is SafetyLoaded) {
      emit(currentState.copyWith(selectedType: event.type));
    }
  }
  
  /// 订阅实时警报
  Future<void> _onSubscribeToAlerts(
    SubscribeToAlerts event,
    Emitter<SafetyState> emit,
  ) async {
    await _alertSubscription?.cancel();
    
    final result = await _subscribeToAlerts(NoParams());
    
    result.fold(
      (failure) {
        // 订阅失败时记录错误但不影响主状态
        addError(failure);
      },
      (alertStream) {
        _alertSubscription = alertStream.listen(
          (alert) => add(_AlertReceived(alert)),
          onError: (error) => addError(error),
        );
      },
    );
  }
  
  /// 处理收到的警报
  void _onAlertReceived(
    _AlertReceived event,
    Emitter<SafetyState> emit,
  ) {
    final currentState = state;
    if (currentState is SafetyLoaded) {
      final updatedAlerts = [event.alert, ...currentState.alerts];
      emit(currentState.copyWith(
        alerts: updatedAlerts,
        lastUpdated: DateTime.now(),
      ));
    }
  }
  
  /// 确认警报
  Future<void> _onAcknowledgeAlert(
    AcknowledgeAlert event,
    Emitter<SafetyState> emit,
  ) async {
    final result = await _acknowledgeAlert(AcknowledgeAlertParams(
      alertId: event.alertId,
      userId: event.userId,
    ));
    
    result.fold(
      (failure) {
        final currentState = state;
        emit(SafetyError(
          message: failure.message,
          previousState: currentState is SafetyLoaded ? currentState : null,
        ));
      },
      (_) {
        final currentState = state;
        if (currentState is SafetyLoaded) {
          final updatedAlerts = currentState.alerts.map((alert) {
            if (alert.id == event.alertId) {
              return alert.copyWith(status: AlertStatus.acknowledged);
            }
            return alert;
          }).toList();
          emit(currentState.copyWith(alerts: updatedAlerts));
        }
      },
    );
  }
  
  /// 刷新数据
  Future<void> _onRefreshData(
    RefreshData event,
    Emitter<SafetyState> emit,
  ) async {
    // 不显示加载状态，静默刷新
    final result = await _getSensorReadings(NoParams());
    
    result.fold(
      (failure) => addError(failure),  // 静默处理错误
      (readings) {
        final currentState = state;
        if (currentState is SafetyLoaded) {
          emit(currentState.copyWith(
            readings: readings,
            lastUpdated: DateTime.now(),
          ));
        }
      },
    );
  }
  
  @override
  Future<void> close() {
    _alertSubscription?.cancel();
    return super.close();
  }
}

/// 内部事件 - 用于 Stream 数据
final class _AlertReceived extends SafetyEvent {
  final Alert alert;
  const _AlertReceived(this.alert);
  
  @override
  List<Object?> get props => [alert];
}
```

## UseCase 规范

### UseCase 基类
```dart
// core/usecases/usecase.dart
import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// UseCase 基类
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// 无参数标记类
class NoParams extends Equatable {
  const NoParams();
  
  @override
  List<Object?> get props => [];
}
```

### UseCase 实现
```dart
// domain/usecases/get_sensor_readings.dart
class GetSensorReadings implements UseCase<List<SensorReading>, GetSensorReadingsParams> {
  final SafetyRepository repository;
  
  GetSensorReadings(this.repository);
  
  @override
  Future<Either<Failure, List<SensorReading>>> call(
    GetSensorReadingsParams params,
  ) async {
    return await repository.getSensorReadings(
      startTime: params.startTime,
      endTime: params.endTime,
      sensorType: params.sensorType,
    );
  }
}

class GetSensorReadingsParams extends Equatable {
  final DateTime startTime;
  final DateTime endTime;
  final SensorType? sensorType;
  
  const GetSensorReadingsParams({
    required this.startTime,
    required this.endTime,
    this.sensorType,
  });
  
  @override
  List<Object?> get props => [startTime, endTime, sensorType];
}
```

## Widget 集成规范

### BlocProvider 配置
```dart
// 单个 BLoC
BlocProvider(
  create: (context) => getIt<SafetyBloc>()..add(const LoadSensorData()),
  child: const SafetyMonitoringPage(),
)

// 多个 BLoC
MultiBlocProvider(
  providers: [
    BlocProvider(
      create: (context) => getIt<SafetyBloc>()..add(const LoadSensorData()),
    ),
    BlocProvider(
      create: (context) => getIt<AlertBloc>()..add(const SubscribeToAlerts()),
    ),
  ],
  child: const HomePage(),
)
```

### BlocBuilder 使用
```dart
// 基础用法
BlocBuilder<SafetyBloc, SafetyState>(
  builder: (context, state) {
    return switch (state) {
      SafetyInitial() => const SizedBox.shrink(),
      SafetyLoading() => const LoadingIndicator(),
      SafetyLoaded(:final readings) => SensorReadingList(readings: readings),
      SafetyError(:final message) => ErrorDisplay(message: message),
    };
  },
)

// 带条件重建 - 只在特定条件变化时重建
BlocBuilder<SafetyBloc, SafetyState>(
  buildWhen: (previous, current) {
    if (previous is SafetyLoaded && current is SafetyLoaded) {
      return previous.readings != current.readings;
    }
    return true;
  },
  builder: (context, state) {
    // ...
  },
)
```

### BlocListener 使用
```dart
// 监听状态变化执行副作用
BlocListener<SafetyBloc, SafetyState>(
  listenWhen: (previous, current) => current is SafetyError,
  listener: (context, state) {
    if (state is SafetyError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  child: // ...
)

// 多个监听器
MultiBlocListener(
  listeners: [
    BlocListener<SafetyBloc, SafetyState>(
      listener: _handleSafetyState,
    ),
    BlocListener<AlertBloc, AlertState>(
      listener: _handleAlertState,
    ),
  ],
  child: // ...
)
```

### BlocConsumer 使用
```dart
// 同时需要 builder 和 listener
BlocConsumer<SafetyBloc, SafetyState>(
  listenWhen: (previous, current) => current is SafetyError,
  listener: (context, state) {
    if (state is SafetyError) {
      _showErrorDialog(context, state.message);
    }
  },
  buildWhen: (previous, current) => current is! SafetyError,
  builder: (context, state) {
    // ...
  },
)
```

### BlocSelector 使用
```dart
// 只选择状态的一部分，避免不必要的重建
BlocSelector<SafetyBloc, SafetyState, List<Alert>>(
  selector: (state) {
    if (state is SafetyLoaded) {
      return state.alerts;
    }
    return const [];
  },
  builder: (context, alerts) {
    return AlertList(alerts: alerts);
  },
)
```

## 依赖注入规范

```dart
// injection_container.dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  //========== Features - Safety Monitoring ==========//
  
  // Bloc
  getIt.registerFactory(
    () => SafetyBloc(
      getSensorReadings: getIt(),
      subscribeToAlerts: getIt(),
      acknowledgeAlert: getIt(),
    ),
  );
  
  // Use Cases
  getIt.registerLazySingleton(() => GetSensorReadings(getIt()));
  getIt.registerLazySingleton(() => SubscribeToAlerts(getIt()));
  getIt.registerLazySingleton(() => AcknowledgeAlertUseCase(getIt()));
  
  // Repository
  getIt.registerLazySingleton<SafetyRepository>(
    () => SafetyRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      networkInfo: getIt(),
    ),
  );
  
  // Data Sources
  getIt.registerLazySingleton<SafetyRemoteDataSource>(
    () => SafetyRemoteDataSourceImpl(client: getIt()),
  );
  getIt.registerLazySingleton<SafetyLocalDataSource>(
    () => SafetyLocalDataSourceImpl(database: getIt()),
  );
  
  //========== Core ==========//
  
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt()),
  );
  
  //========== External ==========//
  
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);
  
  getIt.registerLazySingleton(() => http.Client());
  getIt.registerLazySingleton(() => InternetConnectionChecker());
}
```

## 测试规范

### BLoC 单元测试
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetSensorReadings extends Mock implements GetSensorReadings {}
class MockSubscribeToAlerts extends Mock implements SubscribeToAlerts {}
class MockAcknowledgeAlertUseCase extends Mock implements AcknowledgeAlertUseCase {}

void main() {
  late SafetyBloc bloc;
  late MockGetSensorReadings mockGetSensorReadings;
  late MockSubscribeToAlerts mockSubscribeToAlerts;
  late MockAcknowledgeAlertUseCase mockAcknowledgeAlert;
  
  setUp(() {
    mockGetSensorReadings = MockGetSensorReadings();
    mockSubscribeToAlerts = MockSubscribeToAlerts();
    mockAcknowledgeAlert = MockAcknowledgeAlertUseCase();
    bloc = SafetyBloc(
      getSensorReadings: mockGetSensorReadings,
      subscribeToAlerts: mockSubscribeToAlerts,
      acknowledgeAlert: mockAcknowledgeAlert,
    );
  });
  
  tearDown(() {
    bloc.close();
  });
  
  test('initial state should be SafetyInitial', () {
    expect(bloc.state, const SafetyInitial());
  });
  
  group('LoadSensorData', () {
    final testReadings = [
      SensorReading(
        id: '1',
        sensorId: 'sensor-1',
        value: 25.0,
        unit: '°C',
        timestamp: DateTime.now(),
        status: SensorStatus.normal,
      ),
    ];
    
    blocTest<SafetyBloc, SafetyState>(
      'emits [Loading, Loaded] when data is gotten successfully',
      build: () {
        when(() => mockGetSensorReadings(any()))
            .thenAnswer((_) async => Right(testReadings));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSensorData()),
      expect: () => [
        const SafetyLoading(),
        isA<SafetyLoaded>()
            .having((s) => s.readings, 'readings', testReadings),
      ],
    );
    
    blocTest<SafetyBloc, SafetyState>(
      'emits [Loading, Error] when getting data fails',
      build: () {
        when(() => mockGetSensorReadings(any()))
            .thenAnswer((_) async => Left(ServerFailure(message: 'Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSensorData()),
      expect: () => [
        const SafetyLoading(),
        isA<SafetyError>()
            .having((s) => s.message, 'message', 'Error'),
      ],
    );
  });
  
  group('FilterBySensorType', () {
    blocTest<SafetyBloc, SafetyState>(
      'emits updated state with new filter when already loaded',
      seed: () => SafetyLoaded(
        readings: const [],
        alerts: const [],
        lastUpdated: DateTime.now(),
      ),
      build: () => bloc,
      act: (bloc) => bloc.add(const FilterBySensorType(SensorType.temperature)),
      expect: () => [
        isA<SafetyLoaded>()
            .having((s) => s.selectedType, 'selectedType', SensorType.temperature),
      ],
    );
  });
}
```

### Widget 测试
```dart
void main() {
  late MockSafetyBloc mockBloc;
  
  setUp(() {
    mockBloc = MockSafetyBloc();
  });
  
  testWidgets('displays loading indicator when state is Loading', (tester) async {
    when(() => mockBloc.state).thenReturn(const SafetyLoading());
    
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SafetyBloc>.value(
          value: mockBloc,
          child: const SafetyMonitoringPage(),
        ),
      ),
    );
    
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
  
  testWidgets('displays sensor list when state is Loaded', (tester) async {
    final testReadings = [
      SensorReading(
        id: '1',
        sensorId: 'sensor-1',
        value: 25.0,
        unit: '°C',
        timestamp: DateTime.now(),
        status: SensorStatus.normal,
      ),
    ];
    
    when(() => mockBloc.state).thenReturn(SafetyLoaded(
      readings: testReadings,
      alerts: const [],
      lastUpdated: DateTime.now(),
    ));
    
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SafetyBloc>.value(
          value: mockBloc,
          child: const SafetyMonitoringPage(),
        ),
      ),
    );
    
    expect(find.byType(SensorReadingCard), findsOneWidget);
    expect(find.text('25.0°C'), findsOneWidget);
  });
}
```

## 最佳实践总结

### ✅ DO
- 使用 `sealed class` 定义 State 和 Event，确保穷举匹配
- 每个 BLoC 只负责一个功能模块的状态管理
- 使用 `copyWith` 方法更新不可变状态
- 在 `close()` 方法中取消所有订阅
- 使用依赖注入管理 BLoC 依赖
- 使用 `buildWhen` 和 `listenWhen` 优化性能
- 为 BLoC 编写完整的单元测试

### ❌ DON'T
- 在 BLoC 中直接操作 UI
- 在 Widget 中直接调用 Repository
- 创建过于庞大的 State 类
- 在 `builder` 中执行副作用（使用 `listener`）
- 忘记在 `close()` 中清理资源
- 在多个 BLoC 间共享可变状态
