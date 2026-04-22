part of 'dashboard_bloc.dart';

/// 仪表盘加载状态
enum DashboardStatus {
  initial,
  loading,
  loaded,
  error,
}

/// 仪表盘状态
class DashboardState extends Equatable {
  final DashboardStatus status;
  final String currentLabId;
  final String currentLabName;
  final String currentLabSubtitle;
  final int safetyScore;
  final List<Alert> alerts;
  final Map<String, SensorData> sensorDataMap;
  final bool isMqttConnected;
  final DateTime? lastUpdateTime;
  final String environmentStatus;
  final String powerStatus;
  final String waterStatus;
  final String doorStatus;
  final String? errorMessage;
  
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.currentLabId = '',
    this.currentLabName = '',
    this.currentLabSubtitle = '',
    this.safetyScore = 100,
    this.alerts = const [],
    this.sensorDataMap = const {},
    this.isMqttConnected = false,
    this.lastUpdateTime,
    this.environmentStatus = 'review',
    this.powerStatus = 'review',
    this.waterStatus = 'Normal',
    this.doorStatus = 'Review',
    this.errorMessage,
  });
  
  /// 获取未确认的报警数量
  int get unacknowledgedAlertCount =>
      alerts.where((a) => !a.isAcknowledged).length;
  
  /// 获取紧急报警数量
  int get criticalAlertCount =>
      alerts.where((a) => !a.isAcknowledged && a.level == AlertLevel.critical).length;
  
  /// 获取环境数据
  SensorData? getEnvironmentData(String deviceId) {
    return sensorDataMap[deviceId];
  }
  
  /// 获取最新温度
  double? get latestTemperature {
    final envData = sensorDataMap.values.firstWhere(
      (d) => d.deviceType == 'environment',
      orElse: () => SensorData(
        deviceId: '',
        deviceType: '',
        buildingId: '',
        roomId: '',
        timestamp: DateTime.now(),
        values: const {},
      ),
    );
    return envData.temperature;
  }
  
  /// 获取最新湿度
  double? get latestHumidity {
    final envData = sensorDataMap.values.firstWhere(
      (d) => d.deviceType == 'environment',
      orElse: () => SensorData(
        deviceId: '',
        deviceType: '',
        buildingId: '',
        roomId: '',
        timestamp: DateTime.now(),
        values: const {},
      ),
    );
    return envData.humidity;
  }
  
  /// 获取最新功率
  double? get latestPower {
    final powerData = sensorDataMap.values.firstWhere(
      (d) => d.deviceType == 'power',
      orElse: () => SensorData(
        deviceId: '',
        deviceType: '',
        buildingId: '',
        roomId: '',
        timestamp: DateTime.now(),
        values: const {},
      ),
    );
    return powerData.power;
  }

  double? get latestVoc {
    final envData = sensorDataMap.values.firstWhere(
      (d) => d.deviceType == 'environment',
      orElse: () => SensorData(
        deviceId: '',
        deviceType: '',
        buildingId: '',
        roomId: '',
        timestamp: DateTime.now(),
        values: const {},
      ),
    );
    return envData.vocIndex;
  }
  
  DashboardState copyWith({
    DashboardStatus? status,
    String? currentLabId,
    String? currentLabName,
    String? currentLabSubtitle,
    int? safetyScore,
    List<Alert>? alerts,
    Map<String, SensorData>? sensorDataMap,
    bool? isMqttConnected,
    DateTime? lastUpdateTime,
    String? environmentStatus,
    String? powerStatus,
    String? waterStatus,
    String? doorStatus,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      currentLabId: currentLabId ?? this.currentLabId,
      currentLabName: currentLabName ?? this.currentLabName,
      currentLabSubtitle: currentLabSubtitle ?? this.currentLabSubtitle,
      safetyScore: safetyScore ?? this.safetyScore,
      alerts: alerts ?? this.alerts,
      sensorDataMap: sensorDataMap ?? this.sensorDataMap,
      isMqttConnected: isMqttConnected ?? this.isMqttConnected,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      environmentStatus: environmentStatus ?? this.environmentStatus,
      powerStatus: powerStatus ?? this.powerStatus,
      waterStatus: waterStatus ?? this.waterStatus,
      doorStatus: doorStatus ?? this.doorStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  List<Object?> get props => [
    status,
    currentLabId,
    currentLabName,
    currentLabSubtitle,
    safetyScore,
    alerts,
    sensorDataMap,
    isMqttConnected,
    lastUpdateTime,
    environmentStatus,
    powerStatus,
    waterStatus,
    doorStatus,
    errorMessage,
  ];
}
