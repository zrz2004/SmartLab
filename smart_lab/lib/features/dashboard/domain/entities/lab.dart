import 'package:equatable/equatable.dart';

class Lab extends Equatable {
  final String id;
  final String name;
  final String buildingId;
  final String buildingName;
  final String floor;
  final String roomNumber;
  final LabType type;
  final String? manager;
  final int deviceCount;
  final int safetyScore;
  final LabStatus status;

  const Lab({
    required this.id,
    required this.name,
    required this.buildingId,
    required this.buildingName,
    required this.floor,
    required this.roomNumber,
    required this.type,
    this.manager,
    this.deviceCount = 0,
    this.safetyScore = 100,
    this.status = LabStatus.normal,
  });

  factory Lab.fromJson(Map<String, dynamic> json) {
    return Lab(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      buildingId: json['building_id'] as String? ?? '',
      buildingName: json['building_name'] as String? ?? '',
      floor: json['floor'] as String? ?? '',
      roomNumber: json['room_number'] as String? ?? '',
      type: LabType.fromString(json['type'] as String?),
      manager: json['manager'] as String?,
      deviceCount: json['device_count'] as int? ?? 0,
      safetyScore: json['safety_score'] as int? ?? 100,
      status: LabStatus.fromString(json['status'] as String?),
    );
  }

  String get fullLocation => '$buildingName $floor $roomNumber';

  @override
  List<Object?> get props => [id, name, buildingId, roomNumber, type, status];
}

enum LabType {
  chemistry,
  physics,
  biology,
  electronics,
  computer,
  general;

  static LabType fromString(String? value) {
    return LabType.values.firstWhere(
      (item) => item.name == (value ?? '').toLowerCase(),
      orElse: () => LabType.general,
    );
  }

  String get displayName {
    switch (this) {
      case LabType.chemistry:
        return '化学实验室';
      case LabType.physics:
        return '物理实验室';
      case LabType.biology:
        return '生物实验室';
      case LabType.electronics:
        return '电子实验室';
      case LabType.computer:
        return '计算机实验室';
      case LabType.general:
        return '综合实验室';
    }
  }
}

enum LabStatus {
  normal,
  warning,
  alert,
  offline,
  maintenance;

  static LabStatus fromString(String? value) {
    return LabStatus.values.firstWhere(
      (item) => item.name == (value ?? '').toLowerCase(),
      orElse: () => LabStatus.normal,
    );
  }

  String get displayName {
    switch (this) {
      case LabStatus.normal:
        return '正常';
      case LabStatus.warning:
        return '预警';
      case LabStatus.alert:
        return '告警';
      case LabStatus.offline:
        return '离线';
      case LabStatus.maintenance:
        return '维护中';
    }
  }
}

class Device extends Equatable {
  final String id;
  final String name;
  final DeviceType type;
  final String labId;
  final String? position;
  final DeviceStatus status;
  final DateTime? lastOnlineTime;
  final Map<String, dynamic>? metadata;

  const Device({
    required this.id,
    required this.name,
    required this.type,
    required this.labId,
    this.position,
    this.status = DeviceStatus.offline,
    this.lastOnlineTime,
    this.metadata,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      type: DeviceType.fromString(json['type'] as String?),
      labId: json['lab_id'] as String? ?? '',
      position: json['position'] as String?,
      status: DeviceStatus.fromString(json['status'] as String?),
      lastOnlineTime: json['last_online_time'] != null
          ? DateTime.tryParse(json['last_online_time'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [id, name, type, labId, status];
}

enum DeviceType {
  environmentSensor,
  powerMonitor,
  smartSocket,
  smartBreaker,
  waterSensor,
  flowMeter,
  electroValve,
  doorSensor,
  windowSensor,
  pirSensor,
  rfidReader,
  camera,
  gateway;

  static DeviceType fromString(String? value) {
    return DeviceType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => DeviceType.environmentSensor,
    );
  }

  String get displayName {
    switch (this) {
      case DeviceType.environmentSensor:
        return '环境传感器';
      case DeviceType.powerMonitor:
        return '电源监测';
      case DeviceType.smartSocket:
        return '智能插座';
      case DeviceType.smartBreaker:
        return '智能断路器';
      case DeviceType.waterSensor:
        return '水路传感器';
      case DeviceType.flowMeter:
        return '流量计';
      case DeviceType.electroValve:
        return '电磁阀';
      case DeviceType.doorSensor:
        return '门禁传感器';
      case DeviceType.windowSensor:
        return '窗户传感器';
      case DeviceType.pirSensor:
        return '人体红外传感器';
      case DeviceType.rfidReader:
        return 'RFID 读卡器';
      case DeviceType.camera:
        return '摄像头';
      case DeviceType.gateway:
        return '网关';
    }
  }
}

enum DeviceStatus {
  online,
  offline,
  warning,
  error;

  static DeviceStatus fromString(String? value) {
    return DeviceStatus.values.firstWhere(
      (item) => item.name == (value ?? '').toLowerCase(),
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
