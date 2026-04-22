import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/lab_config.dart';
import '../../../../core/constants/mock_data_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/mqtt_service.dart';
import '../../domain/entities/sensor_data.dart';
import '../../../alerts/domain/entities/alert.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final MqttService mqttService;
  final ApiService apiService;
  final LocalStorageService storageService;

  StreamSubscription<SensorData>? _sensorSubscription;
  StreamSubscription<Alert>? _alertSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  DashboardBloc({
    required this.mqttService,
    required this.apiService,
    required this.storageService,
  }) : super(const DashboardState()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<SensorDataReceived>(_onSensorDataReceived);
    on<AlertReceived>(_onAlertReceived);
    on<MqttConnectionChanged>(_onMqttConnectionChanged);
    on<AcknowledgeAlert>(_onAcknowledgeAlert);
    on<RefreshDashboard>(_onRefreshDashboard);

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

    final currentLabId = storageService.getCurrentLabId() ?? MockDataProvider.currentLabId;

    try {
      final accessibleLabs = await apiService.getAccessibleLabs();
      final currentLab = accessibleLabs.cast<Map<String, dynamic>?>().firstWhere(
            (lab) => lab?['id'] == currentLabId,
            orElse: () => accessibleLabs.isNotEmpty ? accessibleLabs.first : null,
          );
      final resolvedLabId = (currentLab?['id'] as String?) ?? currentLabId;
      final displayLab = LabConfig.getLabById(resolvedLabId) ?? MockDataProvider.currentLab;
      final environmentInspection = await _fetchLatestInspection(
        labId: resolvedLabId,
        sceneType: 'environment',
        deviceType: 'environment_sensor',
      );
      final powerInspection = await _fetchLatestInspection(
        labId: resolvedLabId,
        sceneType: 'power',
        deviceType: 'main_power',
      );
      final waterInspection = await _fetchLatestInspection(
        labId: resolvedLabId,
        sceneType: 'water',
        deviceType: 'main_valve',
      );
      final securityInspection = await _fetchLatestInspection(
        labId: resolvedLabId,
        sceneType: 'security',
        deviceType: 'door_window',
      );

      final alerts = await apiService.getAlerts(
        acknowledged: false,
        labId: resolvedLabId,
        limit: 10,
      );
      final alertList = alerts.map(Alert.fromJson).toList();

      final devices = await apiService.getDevices(roomId: resolvedLabId);
      final telemetryEntries = <SensorData>[];
      for (final device in devices.take(8)) {
        final detail = await apiService.getDeviceDetail(device['id'].toString());
        final telemetry = Map<String, dynamic>.from(detail['telemetry'] as Map? ?? const {});
        final sensorData = _buildSensorDataFromDevice(
          device: device,
          detail: detail,
          telemetry: telemetry,
        );
        if (sensorData != null) {
          telemetryEntries.add(sensorData);
        }
      }

      final sensorMap = {
        for (final item in telemetryEntries) item.deviceId: item,
      };
      _mergeFallbackTelemetry(sensorMap, resolvedLabId);
      final score = await apiService.getLabSafetyScore(resolvedLabId);

      emit(
        state.copyWith(
          status: DashboardStatus.loaded,
          currentLabId: resolvedLabId,
          currentLabName: displayLab.name,
          currentLabSubtitle: displayLab.englishName,
          alerts: alertList,
          sensorDataMap: sensorMap,
          safetyScore: (score['score'] as num?)?.round() ?? _calculateSafetyScore(alertList, sensorMap),
          environmentStatus: _resolveEnvironmentStatus(sensorMap, alertList, environmentInspection),
          powerStatus: _resolvePowerStatus(sensorMap, alertList, powerInspection),
          waterStatus: _resolveWaterStatus(sensorMap, waterInspection),
          doorStatus: _resolveDoorStatus(sensorMap, alertList, securityInspection),
          lastUpdateTime: DateTime.now(),
        ),
      );
    } catch (_) {
      final currentLab = MockDataProvider.currentLab;
      emit(state.copyWith(
        status: DashboardStatus.loaded,
        currentLabId: currentLab.id,
        currentLabName: currentLab.name,
        currentLabSubtitle: currentLab.englishName,
        safetyScore: MockDataProvider.calculateSafetyScore(),
        environmentStatus: 'normal',
        powerStatus: 'normal',
        waterStatus: 'Normal',
        doorStatus: 'Review',
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
      environmentStatus: _resolveEnvironmentStatus(updatedMap, state.alerts, null),
      powerStatus: _resolvePowerStatus(updatedMap, state.alerts, null),
      waterStatus: _resolveWaterStatus(updatedMap, null),
      doorStatus: _resolveDoorStatus(updatedMap, state.alerts, null),
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
      environmentStatus: _resolveEnvironmentStatus(state.sensorDataMap, updatedAlerts, null),
      powerStatus: _resolvePowerStatus(state.sensorDataMap, updatedAlerts, null),
      doorStatus: _resolveDoorStatus(state.sensorDataMap, updatedAlerts, null),
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
        environmentStatus: _resolveEnvironmentStatus(state.sensorDataMap, updatedAlerts, null),
        powerStatus: _resolvePowerStatus(state.sensorDataMap, updatedAlerts, null),
        doorStatus: _resolveDoorStatus(state.sensorDataMap, updatedAlerts, null),
      ));
    } catch (_) {}
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    add(LoadDashboardData());
  }

  SensorData? _buildSensorDataFromDevice({
    required Map<String, dynamic> device,
    required Map<String, dynamic> detail,
    required Map<String, dynamic> telemetry,
  }) {
    final rawType = (detail['type'] ?? device['type'] ?? '').toString();
    final deviceType = switch (rawType) {
      'environmentSensor' => 'environment',
      'powerMonitor' => 'power',
      'waterSensor' => 'water',
      'doorSensor' => 'security',
      'windowSensor' => 'security',
      _ => rawType,
    };
    if (deviceType.isEmpty) {
      return null;
    }

    final normalizedTelemetry = <String, dynamic>{};
    telemetry.forEach((key, value) {
      normalizedTelemetry[key] = value;
      if (key == 'voc') {
        normalizedTelemetry['voc_index'] = value;
      }
      if (key == 'waterLeak') {
        normalizedTelemetry['water_leak_level'] = value;
      }
    });

    return SensorData(
      deviceId: device['id'].toString(),
      deviceType: deviceType,
      buildingId: (detail['building_id'] ?? '').toString(),
      roomId: (detail['room_id'] ?? detail['lab_id'] ?? '').toString(),
      timestamp: DateTime.now(),
      values: normalizedTelemetry,
      status: DeviceStatus.fromString((detail['status'] ?? 'online').toString()),
    );
  }

  void _mergeFallbackTelemetry(Map<String, SensorData> sensorMap, String labId) {
    final now = DateTime.now();

    if (!sensorMap.values.any((item) => item.deviceType == 'environment')) {
      sensorMap['mock_env_$labId'] = SensorData(
        deviceId: 'mock_env_$labId',
        deviceType: 'environment',
        buildingId: '',
        roomId: labId,
        timestamp: now,
        values: {
          'temperature': MockDataProvider.getTemperature(),
          'humidity': MockDataProvider.getHumidity(),
          'voc_index': MockDataProvider.getVocIndex(),
          'pm25': MockDataProvider.getPm25(),
        },
      );
    }

    if (!sensorMap.values.any((item) => item.deviceType == 'power')) {
      sensorMap['mock_power_$labId'] = SensorData(
        deviceId: 'mock_power_$labId',
        deviceType: 'power',
        buildingId: '',
        roomId: labId,
        timestamp: now,
        values: {
          'power': MockDataProvider.getTotalPower(),
          'voltage': MockDataProvider.getVoltage(),
          'leakageCurrent': MockDataProvider.getLeakageCurrent(),
        },
      );
    }

    if (!sensorMap.values.any((item) => item.deviceType == 'water')) {
      sensorMap['mock_water_$labId'] = SensorData(
        deviceId: 'mock_water_$labId',
        deviceType: 'water',
        buildingId: '',
        roomId: labId,
        timestamp: now,
        values: {
          'water_leak_level': MockDataProvider.getWaterLeakLevel(),
        },
      );
    }

    if (!sensorMap.values.any((item) => item.deviceType == 'security')) {
      final hasOpenWindow = MockDataProvider.getWindowData().any((item) => item.isOpen);
      sensorMap['mock_security_$labId'] = SensorData(
        deviceId: 'mock_security_$labId',
        deviceType: 'security',
        buildingId: '',
        roomId: labId,
        timestamp: now,
        values: {
          'window_open': hasOpenWindow,
        },
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchLatestInspection({
    required String labId,
    required String sceneType,
    required String deviceType,
  }) async {
    try {
      return await apiService.getLatestAiInspection(
        labId: labId,
        sceneType: sceneType,
        deviceType: deviceType,
      );
    } catch (_) {
      return null;
    }
  }

  String _resolveEnvironmentStatus(
    Map<String, SensorData> sensorMap,
    List<Alert> alerts,
    Map<String, dynamic>? inspection,
  ) {
    final inspectionRisk = _mapRiskLevelToStatus(inspection?['riskLevel'] as String?);
    if (inspectionRisk != null) {
      return inspectionRisk;
    }
    final hasEnvAlert = alerts.any((alert) =>
        !alert.isAcknowledged &&
        (alert.type == AlertType.temperatureHigh ||
            alert.type == AlertType.temperatureLow ||
            alert.type == AlertType.humidityHigh ||
            alert.type == AlertType.humidityLow ||
            alert.type == AlertType.vocHigh ||
            alert.type == AlertType.gasLeak));
    if (hasEnvAlert) {
      return 'warning';
    }
    return sensorMap.values.any((item) => item.deviceType == 'environment') ? 'normal' : 'review';
  }

  String _resolvePowerStatus(
    Map<String, SensorData> sensorMap,
    List<Alert> alerts,
    Map<String, dynamic>? inspection,
  ) {
    final inspectionRisk = _mapRiskLevelToStatus(inspection?['riskLevel'] as String?);
    if (inspectionRisk != null) {
      return inspectionRisk;
    }
    final hasPowerAlert = alerts.any((alert) =>
        !alert.isAcknowledged &&
        (alert.type == AlertType.powerOverload ||
            alert.type == AlertType.leakageCurrent ||
            alert.type == AlertType.arcFault ||
            alert.type == AlertType.voltageAbnormal));
    if (hasPowerAlert) {
      return 'warning';
    }
    return sensorMap.values.any((item) => item.deviceType == 'power') ? 'normal' : 'review';
  }

  String _resolveWaterStatus(Map<String, SensorData> sensorMap, Map<String, dynamic>? inspection) {
    final inspectionRisk = _mapRiskLevelToStatus(inspection?['riskLevel'] as String?);
    if (inspectionRisk != null) {
      return inspectionRisk;
    }
    final waterSensors = sensorMap.values.where((item) => item.deviceType == 'water');
    if (waterSensors.any((item) => (item.getValue<num>('water_leak_level')?.toDouble() ?? 0) > 0)) {
      return 'warning';
    }
    return waterSensors.isNotEmpty ? 'normal' : 'review';
  }

  String _resolveDoorStatus(
    Map<String, SensorData> sensorMap,
    List<Alert> alerts,
    Map<String, dynamic>? inspection,
  ) {
    final inspectionRisk = _mapRiskLevelToStatus(inspection?['riskLevel'] as String?);
    if (inspectionRisk != null) {
      return inspectionRisk;
    }
    final hasSecurityAlert = alerts.any((alert) =>
        !alert.isAcknowledged &&
        (alert.type == AlertType.doorUnlocked || alert.type == AlertType.windowOpen));
    if (hasSecurityAlert) {
      return 'warning';
    }
    final securitySensors = sensorMap.values.where((item) => item.deviceType == 'security');
    if (securitySensors.any((item) => item.getValue<bool>('window_open') == true)) {
      return 'warning';
    }
    if (MockDataProvider.getDoorData().every((item) => item.isLocked)) {
      return 'normal';
    }
    return 'review';
  }

  String? _mapRiskLevelToStatus(String? riskLevel) {
    switch (riskLevel?.toLowerCase()) {
      case 'critical':
        return 'critical';
      case 'warning':
        return 'warning';
      case 'info':
        return 'normal';
      default:
        return null;
    }
  }

  int _calculateSafetyScore(
    List<Alert> alerts,
    Map<String, SensorData> sensorData,
  ) {
    int score = 100;

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
