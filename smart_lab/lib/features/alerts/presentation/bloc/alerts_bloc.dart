import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/mqtt_service.dart';
import '../../domain/entities/alert.dart';

part 'alerts_event.dart';
part 'alerts_state.dart';

/// 告警中心 BLoC
class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  final ApiService apiService;
  final MqttService mqttService;
  StreamSubscription<Alert>? _subscription;
  
  AlertsBloc({
    required this.apiService,
    required this.mqttService,
  }) : super(const AlertsState()) {
    on<LoadAlerts>(_onLoadAlerts);
    on<AlertReceived>(_onAlertReceived);
    on<AcknowledgeAlert>(_onAcknowledgeAlert);
    on<FilterAlerts>(_onFilterAlerts);
    on<ClearAllAlerts>(_onClearAllAlerts);
    
    _subscribeToAlerts();
  }
  
  void _subscribeToAlerts() {
    _subscription = mqttService.alertStream.listen((alert) {
      add(AlertReceived(alert));
    });
  }
  
  void _onLoadAlerts(
    LoadAlerts event,
    Emitter<AlertsState> emit,
  ) {
    emit(state.copyWith(status: AlertsStatus.loading));
    
    // 模拟历史告警数据
    final alerts = [
      Alert(
        id: 'alert_001',
        type: AlertType.temperatureHigh,
        level: AlertLevel.warning,
        title: '温度偏高预警',
        message: '实验室温度达到 28.5°C，超过预警阈值',
        deviceId: 'temp_sensor_01',
        deviceName: '温度传感器 #1',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      Alert(
        id: 'alert_002',
        type: AlertType.leakageCurrent,
        level: AlertLevel.critical,
        title: '漏电流超标',
        message: '检测到漏电流 32mA，请立即检查电路',
        deviceId: 'power_monitor_01',
        deviceName: '电源监测器',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isAcknowledged: true,
        acknowledgedBy: '张润哲',
        acknowledgedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      Alert(
        id: 'alert_003',
        type: AlertType.windowOpen,
        level: AlertLevel.info,
        title: '窗户开启提醒',
        message: '南侧窗户 #1 已开启 2 小时',
        deviceId: 'window_sensor_01',
        deviceName: '窗户传感器 #1',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Alert(
        id: 'alert_004',
        type: AlertType.chemicalExpired,
        level: AlertLevel.warning,
        title: '危化品即将过期',
        message: '甲醇（CAS: 67-56-1）将于 30 天后过期',
        deviceId: 'chem_004',
        deviceName: '危化品管理系统',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Alert(
        id: 'alert_005',
        type: AlertType.vocHigh,
        level: AlertLevel.warning,
        title: 'VOC 浓度偏高',
        message: 'VOC 指数达到 180，请加强通风',
        deviceId: 'voc_sensor_01',
        deviceName: 'VOC 传感器',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isAcknowledged: true,
      ),
    ];
    
    emit(state.copyWith(
      status: AlertsStatus.loaded,
      alerts: alerts,
      filteredAlerts: alerts,
    ));
  }
  
  void _onAlertReceived(
    AlertReceived event,
    Emitter<AlertsState> emit,
  ) {
    final updatedAlerts = [event.alert, ...state.alerts];
    emit(state.copyWith(
      alerts: updatedAlerts,
      filteredAlerts: _applyFilter(updatedAlerts, state.selectedLevel),
    ));
  }
  
  Future<void> _onAcknowledgeAlert(
    AcknowledgeAlert event,
    Emitter<AlertsState> emit,
  ) async {
    final updatedAlerts = state.alerts.map((alert) {
      if (alert.id == event.alertId) {
        return alert.copyWith(
          isAcknowledged: true,
          acknowledgedBy: '张润哲',
          acknowledgedAt: DateTime.now(),
        );
      }
      return alert;
    }).toList();
    
    emit(state.copyWith(
      alerts: updatedAlerts,
      filteredAlerts: _applyFilter(updatedAlerts, state.selectedLevel),
    ));
  }
  
  void _onFilterAlerts(
    FilterAlerts event,
    Emitter<AlertsState> emit,
  ) {
    emit(state.copyWith(
      selectedLevel: event.level,
      filteredAlerts: _applyFilter(state.alerts, event.level),
    ));
  }
  
  void _onClearAllAlerts(
    ClearAllAlerts event,
    Emitter<AlertsState> emit,
  ) {
    final updatedAlerts = state.alerts.map((alert) {
      return alert.copyWith(
        isAcknowledged: true,
        acknowledgedAt: DateTime.now(),
      );
    }).toList();
    
    emit(state.copyWith(
      alerts: updatedAlerts,
      filteredAlerts: _applyFilter(updatedAlerts, state.selectedLevel),
    ));
  }
  
  List<Alert> _applyFilter(List<Alert> alerts, AlertLevel? level) {
    if (level == null) return alerts;
    return alerts.where((alert) => alert.level == level).toList();
  }
  
  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
