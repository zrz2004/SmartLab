import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/services/mqtt_service.dart';
import '../../../../core/constants/safety_thresholds.dart';
import '../../../dashboard/domain/entities/sensor_data.dart';

part 'environment_event.dart';
part 'environment_state.dart';

/// 环境监测 BLoC
class EnvironmentBloc extends Bloc<EnvironmentEvent, EnvironmentState> {
  final MqttService mqttService;
  StreamSubscription<SensorData>? _subscription;
  
  // 历史数据缓存 (最近60个数据点)
  final List<FlSpot> _temperatureHistory = [];
  final List<FlSpot> _humidityHistory = [];
  final List<FlSpot> _vocHistory = [];
  int _dataIndex = 0;
  
  EnvironmentBloc({
    required this.mqttService,
  }) : super(const EnvironmentState()) {
    on<LoadEnvironmentData>(_onLoadEnvironmentData);
    on<EnvironmentDataReceived>(_onEnvironmentDataReceived);
    on<SetAlarmThreshold>(_onSetAlarmThreshold);
    
    _subscribeToData();
  }
  
  void _subscribeToData() {
    _subscription = mqttService.sensorDataStream
        .where((data) => data.deviceType == 'environment')
        .listen((data) {
      add(EnvironmentDataReceived(data));
    });
  }
  
  void _onLoadEnvironmentData(
    LoadEnvironmentData event,
    Emitter<EnvironmentState> emit,
  ) {
    emit(state.copyWith(status: EnvironmentStatus.loading));
    
    // 初始化模拟数据
    _initMockData();
    
    emit(state.copyWith(
      status: EnvironmentStatus.loaded,
      temperatureHistory: List.from(_temperatureHistory),
      humidityHistory: List.from(_humidityHistory),
      vocHistory: List.from(_vocHistory),
    ));
  }
  
  void _initMockData() {
    // 生成模拟历史数据
    for (var i = 0; i < 30; i++) {
      _temperatureHistory.add(FlSpot(
        i.toDouble(),
        22 + (i % 5) * 0.5,
      ));
      _humidityHistory.add(FlSpot(
        i.toDouble(),
        45 + (i % 8) - 4,
      ));
      _vocHistory.add(FlSpot(
        i.toDouble(),
        100 + (i % 10) * 10,
      ));
      _dataIndex = i + 1;
    }
  }
  
  void _onEnvironmentDataReceived(
    EnvironmentDataReceived event,
    Emitter<EnvironmentState> emit,
  ) {
    final data = event.data;
    
    // 更新历史数据
    if (data.temperature != null) {
      _temperatureHistory.add(FlSpot(_dataIndex.toDouble(), data.temperature!));
      if (_temperatureHistory.length > 60) {
        _temperatureHistory.removeAt(0);
      }
    }
    
    if (data.humidity != null) {
      _humidityHistory.add(FlSpot(_dataIndex.toDouble(), data.humidity!));
      if (_humidityHistory.length > 60) {
        _humidityHistory.removeAt(0);
      }
    }
    
    if (data.vocIndex != null) {
      _vocHistory.add(FlSpot(_dataIndex.toDouble(), data.vocIndex!));
      if (_vocHistory.length > 60) {
        _vocHistory.removeAt(0);
      }
    }
    
    _dataIndex++;
    
    // 检查阈值
    final tempLevel = SafetyThresholds.getTemperatureLevel(data.temperature ?? 22);
    final humidityLevel = SafetyThresholds.getHumidityLevel(data.humidity ?? 45);
    final vocLevel = SafetyThresholds.getVocLevel(data.vocIndex ?? 100);
    
    emit(state.copyWith(
      currentTemperature: data.temperature,
      currentHumidity: data.humidity,
      currentVoc: data.vocIndex,
      currentPm25: data.pm25,
      temperatureLevel: tempLevel,
      humidityLevel: humidityLevel,
      vocLevel: vocLevel,
      temperatureHistory: List.from(_temperatureHistory),
      humidityHistory: List.from(_humidityHistory),
      vocHistory: List.from(_vocHistory),
      lastUpdateTime: DateTime.now(),
    ));
  }
  
  void _onSetAlarmThreshold(
    SetAlarmThreshold event,
    Emitter<EnvironmentState> emit,
  ) {
    // TODO: 保存阈值配置到服务器
  }
  
  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
