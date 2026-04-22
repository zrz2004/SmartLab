import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/mqtt_service.dart';
import '../../domain/entities/alert.dart';

part 'alerts_event.dart';
part 'alerts_state.dart';

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

    _subscription = mqttService.alertStream.listen(
      (alert) => add(AlertReceived(alert)),
    );
  }

  Future<void> _onLoadAlerts(
    LoadAlerts event,
    Emitter<AlertsState> emit,
  ) async {
    emit(state.copyWith(status: AlertsStatus.loading, errorMessage: null));

    try {
      final response = await apiService.getAlerts(limit: 50);
      final alerts = response.map(Alert.fromJson).toList();

      emit(
        state.copyWith(
          status: AlertsStatus.loaded,
          alerts: alerts,
          filteredAlerts: _applyFilter(alerts, state.selectedLevel),
          errorMessage: null,
        ),
      );
    } catch (_) {
      final alerts = [
        Alert(
          id: 'alert_001',
          type: AlertType.temperatureHigh,
          level: AlertLevel.warning,
          title: '温度预警',
          message: '实验室温度达到 28.5°C。',
          deviceId: 'temp_sensor_01',
          deviceName: '温度传感器 #1',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        Alert(
          id: 'alert_ai_001',
          type: AlertType.windowOpen,
          level: AlertLevel.warning,
          title: 'AI 图像预警',
          message: 'AI 复核检测到窗户疑似开启，请人工确认。',
          deviceId: 'camera_ai_01',
          deviceName: 'AI 图像巡检',
          timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
          snapshot: const {
            'source': 'ai',
            'model': 'Qwen/Qwen3-VL-32B-Instruct',
            'confidence': '82%',
            'reviewStatus': 'pending_review',
          },
        ),
        Alert(
          id: 'alert_002',
          type: AlertType.leakageCurrent,
          level: AlertLevel.critical,
          title: '漏电流严重警告',
          message: '漏电流达到 32mA。',
          deviceId: 'power_monitor_01',
          deviceName: '电源监测器',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          isAcknowledged: true,
          acknowledgedBy: '值班人员',
          acknowledgedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
      ];

      emit(
        state.copyWith(
          status: AlertsStatus.loaded,
          alerts: alerts,
          filteredAlerts: _applyFilter(alerts, state.selectedLevel),
          errorMessage: '已加载本地报警兜底数据。',
        ),
      );
    }
  }

  void _onAlertReceived(AlertReceived event, Emitter<AlertsState> emit) {
    final updatedAlerts = [event.alert, ...state.alerts];
    emit(
      state.copyWith(
        alerts: updatedAlerts,
        filteredAlerts: _applyFilter(updatedAlerts, state.selectedLevel),
      ),
    );
  }

  Future<void> _onAcknowledgeAlert(
    AcknowledgeAlert event,
    Emitter<AlertsState> emit,
  ) async {
    try {
      await apiService.acknowledgeAlert(event.alertId);
    } catch (_) {}

    final updatedAlerts = state.alerts.map((alert) {
      if (alert.id == event.alertId) {
        return alert.copyWith(
          isAcknowledged: true,
          acknowledgedBy: '值班人员',
          acknowledgedAt: DateTime.now(),
        );
      }
      return alert;
    }).toList();

    emit(
      state.copyWith(
        alerts: updatedAlerts,
        filteredAlerts: _applyFilter(updatedAlerts, state.selectedLevel),
      ),
    );
  }

  void _onFilterAlerts(FilterAlerts event, Emitter<AlertsState> emit) {
    emit(
      state.copyWith(
        selectedLevel: event.level,
        filteredAlerts: _applyFilter(state.alerts, event.level),
      ),
    );
  }

  void _onClearAllAlerts(ClearAllAlerts event, Emitter<AlertsState> emit) {
    final updatedAlerts = state.alerts
        .map(
          (alert) => alert.copyWith(
            isAcknowledged: true,
            acknowledgedAt: DateTime.now(),
          ),
        )
        .toList();
    emit(
      state.copyWith(
        alerts: updatedAlerts,
        filteredAlerts: _applyFilter(updatedAlerts, state.selectedLevel),
      ),
    );
  }

  List<Alert> _applyFilter(List<Alert> alerts, AlertLevel? level) {
    if (level == null) return alerts;
    return alerts.where((alert) => alert.level == level).toList();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
