import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/services/mqtt_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/mock_data_provider.dart';
import '../../domain/entities/sensor_data.dart';
import '../../../alerts/domain/entities/alert.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

/// 仪表盘 BLoC
/// 
/// 管理首页仪表盘的状态
/// - 接收 MQTT 实时数据
/// - 计算安全评分
/// - 管理报警列表
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final MqttService mqttService;
  final ApiService apiService;
  
  StreamSubscription<SensorData>? _sensorSubscription;
  StreamSubscription<Alert>? _alertSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  
  DashboardBloc({
    required this.mqttService,
    required this.apiService,
  }) : super(const DashboardState()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<SensorDataReceived>(_onSensorDataReceived);
    on<AlertReceived>(_onAlertReceived);
    on<MqttConnectionChanged>(_onMqttConnectionChanged);
    on<AcknowledgeAlert>(_onAcknowledgeAlert);
    on<RefreshDashboard>(_onRefreshDashboard);
    
    // 订阅 MQTT 数据流
    _subscribeToMqtt();
  }
  
  void _subscribeToMqtt() {
    _sensorSubscription = mqttService.sensorDataStream.listen((data) {
      add(SensorDataReceived(data));
    });
    
    _alertSubscription = mqttService.alertStream.listen((alert) {
      add(AlertReceived(alert));
    });
    
    _connectionSubscription = mqttService.connectionStateStream.listen((connected) {
      add(MqttConnectionChanged(connected));
    });
  }
  
  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading));
    
    try {
      // 获取当前实验室信息
      final currentLab = MockDataProvider.currentLab;
      
      // 加载初始数据
      final alerts = await apiService.getAlerts(
        acknowledged: false,
        limit: 10,
      );
      
      final alertList = alerts.map((e) => Alert.fromJson(e)).toList();
      
      emit(state.copyWith(
        status: DashboardStatus.loaded,
        currentLabId: currentLab.id,
        currentLabName: currentLab.name,
        alerts: alertList,
        safetyScore: _calculateSafetyScore(alertList, state.sensorDataMap),
      ));
    } catch (e) {
      // 如果API请求失败，仍然加载本地数据
      final currentLab = MockDataProvider.currentLab;
      emit(state.copyWith(
        status: DashboardStatus.loaded,
        currentLabId: currentLab.id,
        currentLabName: currentLab.name,
        safetyScore: MockDataProvider.calculateSafetyScore(),
      ));
    }
  }
  
  void _onSensorDataReceived(
    SensorDataReceived event,
    Emitter<DashboardState> emit,
  ) {
    final updatedMap = Map<String, SensorData>.from(state.sensorDataMap);
    updatedMap[event.data.deviceId] = event.data;
    
    emit(state.copyWith(
      sensorDataMap: updatedMap,
      safetyScore: _calculateSafetyScore(state.alerts, updatedMap),
      lastUpdateTime: DateTime.now(),
    ));
  }
  
  void _onAlertReceived(
    AlertReceived event,
    Emitter<DashboardState> emit,
  ) {
    final updatedAlerts = [event.alert, ...state.alerts];
    
    emit(state.copyWith(
      alerts: updatedAlerts,
      safetyScore: _calculateSafetyScore(updatedAlerts, state.sensorDataMap),
    ));
  }
  
  void _onMqttConnectionChanged(
    MqttConnectionChanged event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(isMqttConnected: event.isConnected));
  }
  
  Future<void> _onAcknowledgeAlert(
    AcknowledgeAlert event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await apiService.acknowledgeAlert(event.alertId);
      
      final updatedAlerts = state.alerts.map((alert) {
        if (alert.id == event.alertId) {
          return alert.copyWith(
            isAcknowledged: true,
            acknowledgedAt: DateTime.now(),
          );
        }
        return alert;
      }).toList();
      
      emit(state.copyWith(
        alerts: updatedAlerts,
        safetyScore: _calculateSafetyScore(updatedAlerts, state.sensorDataMap),
      ));
    } catch (e) {
      // 忽略错误，保持当前状态
    }
  }
  
  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    add(LoadDashboardData());
  }
  
  /// 计算安全评分
  /// 
  /// 基于以下因素:
  /// - 未处理的紧急报警 (每个 -15 分)
  /// - 未处理的预警 (每个 -5 分)
  /// - 设备离线 (每个 -3 分)
  /// - 环境参数异常
  int _calculateSafetyScore(
    List<Alert> alerts,
    Map<String, SensorData> sensorData,
  ) {
    int score = 100;
    
    // 报警扣分
    for (final alert in alerts.where((a) => !a.isAcknowledged)) {
      switch (alert.level) {
        case AlertLevel.critical:
          score -= 15;
          break;
        case AlertLevel.warning:
          score -= 5;
          break;
        case AlertLevel.info:
          score -= 1;
          break;
      }
    }
    
    // 设备状态扣分
    for (final data in sensorData.values) {
      if (data.status == DeviceStatus.offline) {
        score -= 3;
      } else if (data.status == DeviceStatus.error) {
        score -= 5;
      }
    }
    
    return score.clamp(0, 100);
  }
  
  @override
  Future<void> close() {
    _sensorSubscription?.cancel();
    _alertSubscription?.cancel();
    _connectionSubscription?.cancel();
    return super.close();
  }
}
