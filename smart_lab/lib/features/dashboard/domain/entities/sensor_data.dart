import 'package:equatable/equatable.dart';

/// 传感器数据实体
/// 
/// 统一的传感器数据模型，支持多种设备类型
class SensorData extends Equatable {
  final String deviceId;
  final String deviceType;
  final String buildingId;
  final String roomId;
  final DateTime timestamp;
  final Map<String, dynamic> values;
  final DeviceStatus status;
  
  const SensorData({
    required this.deviceId,
    required this.deviceType,
    required this.buildingId,
    required this.roomId,
    required this.timestamp,
    required this.values,
    this.status = DeviceStatus.online,
  });
  
  /// 从 JSON 创建
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      deviceId: json['device_id'] as String,
      deviceType: json['device_type'] as String,
      buildingId: json['building_id'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      values: json['values'] as Map<String, dynamic>? ?? {},
      status: DeviceStatus.fromString(json['status'] as String? ?? 'online'),
    );
  }
  
  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'device_type': deviceType,
      'building_id': buildingId,
      'room_id': roomId,
      'timestamp': timestamp.toIso8601String(),
      'values': values,
      'status': status.name,
    };
  }
  
  /// 获取特定值
  T? getValue<T>(String key) {
    return values[key] as T?;
  }
  
  /// 复制并修改
  SensorData copyWith({
    String? deviceId,
    String? deviceType,
    String? buildingId,
    String? roomId,
    DateTime? timestamp,
    Map<String, dynamic>? values,
    DeviceStatus? status,
  }) {
    return SensorData(
      deviceId: deviceId ?? this.deviceId,
      deviceType: deviceType ?? this.deviceType,
      buildingId: buildingId ?? this.buildingId,
      roomId: roomId ?? this.roomId,
      timestamp: timestamp ?? this.timestamp,
      values: values ?? this.values,
      status: status ?? this.status,
    );
  }
  
  @override
  List<Object?> get props => [deviceId, deviceType, timestamp, values, status];
}

/// 设备状态枚举
enum DeviceStatus {
  online,
  offline,
  warning,
  error;
  
  static DeviceStatus fromString(String value) {
    return DeviceStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => DeviceStatus.offline,
    );
  }
  
  String get displayName {
    switch (this) {
      case DeviceStatus.online:
        return '在线';
      case DeviceStatus.offline:
        return '离线';
      case DeviceStatus.warning:
        return '预警';
      case DeviceStatus.error:
        return '故障';
    }
  }
}

/// 环境传感器数据扩展
extension EnvironmentSensorData on SensorData {
  double? get temperature => getValue<double>('temperature');
  double? get humidity => getValue<double>('humidity');
  double? get vocIndex => getValue<double>('voc_index');
  double? get pm25 => getValue<double>('pm25');
  double? get co2 => getValue<double>('co2');
}

/// 电源传感器数据扩展
extension PowerSensorData on SensorData {
  double? get voltage => getValue<double>('voltage');
  double? get current => getValue<double>('current');
  double? get power => getValue<double>('power');
  double? get leakageCurrent => getValue<double>('leakage_current');
  double? get energy => getValue<double>('energy');
  bool? get isSwitchOn => getValue<bool>('switch_on');
}

/// 水路传感器数据扩展
extension WaterSensorData on SensorData {
  bool? get isLeakDetected => getValue<bool>('leak_detected');
  double? get flowRate => getValue<double>('flow_rate');
  bool? get isValveOpen => getValue<bool>('valve_open');
  int? get continuousFlowMinutes => getValue<int>('continuous_flow_minutes');
}

/// 门窗传感器数据扩展
extension SecuritySensorData on SensorData {
  bool? get isWindowOpen => getValue<bool>('window_open');
  bool? get isDoorLocked => getValue<bool>('door_locked');
  bool? get isMotionDetected => getValue<bool>('motion_detected');
}
