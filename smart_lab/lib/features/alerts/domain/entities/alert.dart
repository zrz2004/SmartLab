import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'].toString(),
      type: AlertType.fromString(json['type'] as String),
      level: AlertLevel.fromString(json['level'] as String),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? '',
      roomId: json['room_id'] as String?,
      buildingId: json['building_id'] as String?,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : DateTime.now(),
      snapshot: json['snapshot'] as Map<String, dynamic>?,
      isAcknowledged: json['is_acknowledged'] as bool? ?? false,
      acknowledgedAt: json['acknowledged_at'] != null ? DateTime.parse(json['acknowledged_at'] as String) : null,
      acknowledgedBy: json['acknowledged_by'] as String?,
    );
  }

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

enum AlertType {
  temperatureHigh,
  temperatureLow,
  humidityHigh,
  humidityLow,
  vocHigh,
  gasLeak,
  powerOverload,
  leakageCurrent,
  arcFault,
  voltageAbnormal,
  waterLeak,
  tapForgotten,
  doorUnlocked,
  windowOpen,
  intrusion,
  chemicalMissing,
  chemicalExpired,
  chemicalIncompatible,
  unauthorizedAccess,
  deviceOffline,
  deviceError,
  batteryLow,
  other;

  static AlertType fromString(String value) {
    return AlertType.values.firstWhere((e) => e.name == value, orElse: () => AlertType.other);
  }

  IconData get icon {
    switch (this) {
      case AlertType.temperatureHigh:
      case AlertType.temperatureLow:
        return Icons.thermostat;
      case AlertType.humidityHigh:
      case AlertType.humidityLow:
      case AlertType.waterLeak:
      case AlertType.tapForgotten:
        return Icons.water_drop;
      case AlertType.vocHigh:
      case AlertType.gasLeak:
        return Icons.air;
      case AlertType.powerOverload:
      case AlertType.leakageCurrent:
      case AlertType.arcFault:
      case AlertType.voltageAbnormal:
        return Icons.flash_on;
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

enum AlertLevel {
  critical,
  warning,
  info;

  static AlertLevel fromString(String value) {
    return AlertLevel.values.firstWhere((e) => e.name == value.toLowerCase(), orElse: () => AlertLevel.info);
  }
}
