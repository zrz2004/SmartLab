import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 报警实体
/// 
/// 支持三级报警分类:
/// - Critical: 紧急报警 (火灾、毒气、水浸)
/// - Warning: 预警 (超标、异常)
/// - Info: 信息 (上下线、提醒)
class Alert extends Equatable {
  final String id;
  final AlertType type;
  final AlertLevel level;
  final String title;
  final String message;
  final String deviceId;
  final String deviceName;
  final String? roomId;
  final String? buildingId;
  final DateTime timestamp;
  final Map<String, dynamic>? snapshot;
  final bool isAcknowledged;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  
  const Alert({
    required this.id,
    required this.type,
    required this.level,
    required this.title,
    required this.message,
    required this.deviceId,
    required this.deviceName,
    this.roomId,
    this.buildingId,
    required this.timestamp,
    this.snapshot,
    this.isAcknowledged = false,
    this.acknowledgedAt,
    this.acknowledgedBy,
  });
  
  /// 从 JSON 创建
  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      type: AlertType.fromString(json['type'] as String),
      level: AlertLevel.fromString(json['level'] as String),
      title: json['title'] as String? ?? '',
      message: json['message'] as String,
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String? ?? '',
      roomId: json['room_id'] as String?,
      buildingId: json['building_id'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      snapshot: json['snapshot'] as Map<String, dynamic>?,
      isAcknowledged: json['is_acknowledged'] as bool? ?? false,
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'] as String)
          : null,
      acknowledgedBy: json['acknowledged_by'] as String?,
    );
  }
  
  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'level': level.name,
      'title': title,
      'message': message,
      'device_id': deviceId,
      'device_name': deviceName,
      'room_id': roomId,
      'building_id': buildingId,
      'timestamp': timestamp.toIso8601String(),
      'snapshot': snapshot,
      'is_acknowledged': isAcknowledged,
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'acknowledged_by': acknowledgedBy,
    };
  }
  
  /// 复制并修改
  Alert copyWith({
    String? id,
    AlertType? type,
    AlertLevel? level,
    String? title,
    String? message,
    String? deviceId,
    String? deviceName,
    String? roomId,
    String? buildingId,
    DateTime? timestamp,
    Map<String, dynamic>? snapshot,
    bool? isAcknowledged,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
  }) {
    return Alert(
      id: id ?? this.id,
      type: type ?? this.type,
      level: level ?? this.level,
      title: title ?? this.title,
      message: message ?? this.message,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      roomId: roomId ?? this.roomId,
      buildingId: buildingId ?? this.buildingId,
      timestamp: timestamp ?? this.timestamp,
      snapshot: snapshot ?? this.snapshot,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
    );
  }
  
  @override
  List<Object?> get props => [id, type, level, message, timestamp, isAcknowledged];
}

/// 报警类型枚举
enum AlertType {
  // 环境类
  temperatureHigh,
  temperatureLow,
  humidityHigh,
  humidityLow,
  vocHigh,
  gasLeak,
  
  // 电气类
  powerOverload,
  leakageCurrent,
  arcFault,
  voltageAbnormal,
  
  // 水路类
  waterLeak,
  tapForgotten,
  
  // 安防类
  doorUnlocked,
  windowOpen,
  intrusion,
  
  // 危化品类
  chemicalMissing,
  chemicalExpired,
  chemicalIncompatible,
  unauthorizedAccess,
  
  // 设备类
  deviceOffline,
  deviceError,
  batteryLow,
  
  // 其他
  other;
  
  static AlertType fromString(String value) {
    return AlertType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertType.other,
    );
  }
  
  String get displayName {
    switch (this) {
      case AlertType.temperatureHigh:
        return '温度过高';
      case AlertType.temperatureLow:
        return '温度过低';
      case AlertType.humidityHigh:
        return '湿度过高';
      case AlertType.humidityLow:
        return '湿度过低';
      case AlertType.vocHigh:
        return 'VOC超标';
      case AlertType.gasLeak:
        return '气体泄漏';
      case AlertType.powerOverload:
        return '功率过载';
      case AlertType.leakageCurrent:
        return '漏电检测';
      case AlertType.arcFault:
        return '电弧故障';
      case AlertType.voltageAbnormal:
        return '电压异常';
      case AlertType.waterLeak:
        return '水浸报警';
      case AlertType.tapForgotten:
        return '水龙头未关';
      case AlertType.doorUnlocked:
        return '门禁未锁';
      case AlertType.windowOpen:
        return '窗户开启';
      case AlertType.intrusion:
        return '入侵检测';
      case AlertType.chemicalMissing:
        return '试剂丢失';
      case AlertType.chemicalExpired:
        return '试剂过期';
      case AlertType.chemicalIncompatible:
        return '存储违规';
      case AlertType.unauthorizedAccess:
        return '非法领用';
      case AlertType.deviceOffline:
        return '设备离线';
      case AlertType.deviceError:
        return '设备故障';
      case AlertType.batteryLow:
        return '电池电量低';
      case AlertType.other:
        return '其他';
    }
  }
  
  /// 获取报警图标名称
  String get iconName {
    switch (this) {
      case AlertType.temperatureHigh:
      case AlertType.temperatureLow:
        return 'thermometer';
      case AlertType.humidityHigh:
      case AlertType.humidityLow:
        return 'droplets';
      case AlertType.vocHigh:
      case AlertType.gasLeak:
        return 'wind';
      case AlertType.powerOverload:
      case AlertType.leakageCurrent:
      case AlertType.arcFault:
      case AlertType.voltageAbnormal:
        return 'zap';
      case AlertType.waterLeak:
      case AlertType.tapForgotten:
        return 'droplet';
      case AlertType.doorUnlocked:
      case AlertType.windowOpen:
      case AlertType.intrusion:
        return 'shield';
      case AlertType.chemicalMissing:
      case AlertType.chemicalExpired:
      case AlertType.chemicalIncompatible:
      case AlertType.unauthorizedAccess:
        return 'flask';
      case AlertType.deviceOffline:
      case AlertType.deviceError:
      case AlertType.batteryLow:
        return 'activity';
      case AlertType.other:
        return 'alert-triangle';
    }
  }
  
  /// 获取 Flutter 图标
  IconData get icon {
    switch (this) {
      case AlertType.temperatureHigh:
      case AlertType.temperatureLow:
        return Icons.thermostat;
      case AlertType.humidityHigh:
      case AlertType.humidityLow:
        return Icons.water_drop;
      case AlertType.vocHigh:
      case AlertType.gasLeak:
        return Icons.air;
      case AlertType.powerOverload:
      case AlertType.leakageCurrent:
      case AlertType.arcFault:
      case AlertType.voltageAbnormal:
        return Icons.flash_on;
      case AlertType.waterLeak:
      case AlertType.tapForgotten:
        return Icons.water_damage;
      case AlertType.doorUnlocked:
      case AlertType.windowOpen:
      case AlertType.intrusion:
        return Icons.shield;
      case AlertType.chemicalMissing:
      case AlertType.chemicalExpired:
      case AlertType.chemicalIncompatible:
      case AlertType.unauthorizedAccess:
        return Icons.science;
      case AlertType.deviceOffline:
      case AlertType.deviceError:
      case AlertType.batteryLow:
        return Icons.sensors_off;
      case AlertType.other:
        return Icons.warning;
    }
  }
}

/// 报警级别枚举
enum AlertLevel {
  critical,
  warning,
  info;
  
  static AlertLevel fromString(String value) {
    return AlertLevel.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => AlertLevel.info,
    );
  }
  
  String get displayName {
    switch (this) {
      case AlertLevel.critical:
        return '紧急';
      case AlertLevel.warning:
        return '预警';
      case AlertLevel.info:
        return '信息';
    }
  }
  
  int get priority {
    switch (this) {
      case AlertLevel.critical:
        return 3;
      case AlertLevel.warning:
        return 2;
      case AlertLevel.info:
        return 1;
    }
  }
}
