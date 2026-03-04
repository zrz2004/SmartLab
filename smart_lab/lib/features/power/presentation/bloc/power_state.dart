part of 'power_bloc.dart';

enum PowerStatus { initial, loading, loaded, error }

class PowerState extends Equatable {
  final PowerStatus status;
  final String labName;
  final bool isMainPowerOn;
  final double? currentVoltage;
  final double? currentPower;
  final double? leakageCurrent;
  final double? totalEnergy;
  final List<SocketInfo> sockets;
  final bool isControlling;
  final DateTime? lastUpdateTime;
  final String? errorMessage;
  
  const PowerState({
    this.status = PowerStatus.initial,
    this.labName = '',
    this.isMainPowerOn = true,
    this.currentVoltage,
    this.currentPower,
    this.leakageCurrent,
    this.totalEnergy,
    this.sockets = const [],
    this.isControlling = false,
    this.lastUpdateTime,
    this.errorMessage,
  });
  
  PowerState copyWith({
    PowerStatus? status,
    String? labName,
    bool? isMainPowerOn,
    double? currentVoltage,
    double? currentPower,
    double? leakageCurrent,
    double? totalEnergy,
    List<SocketInfo>? sockets,
    bool? isControlling,
    DateTime? lastUpdateTime,
    String? errorMessage,
  }) {
    return PowerState(
      status: status ?? this.status,
      labName: labName ?? this.labName,
      isMainPowerOn: isMainPowerOn ?? this.isMainPowerOn,
      currentVoltage: currentVoltage ?? this.currentVoltage,
      currentPower: currentPower ?? this.currentPower,
      leakageCurrent: leakageCurrent ?? this.leakageCurrent,
      totalEnergy: totalEnergy ?? this.totalEnergy,
      sockets: sockets ?? this.sockets,
      isControlling: isControlling ?? this.isControlling,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  List<Object?> get props => [
    status,
    labName,
    isMainPowerOn,
    currentVoltage,
    currentPower,
    leakageCurrent,
    sockets,
    isControlling,
    lastUpdateTime,
  ];
}

/// 插座信息
class SocketInfo extends Equatable {
  final String id;
  final String name;
  final double power;
  final bool isOn;
  final bool isOverload;
  
  const SocketInfo({
    required this.id,
    required this.name,
    required this.power,
    required this.isOn,
    required this.isOverload,
  });
  
  SocketInfo copyWith({
    String? id,
    String? name,
    double? power,
    bool? isOn,
    bool? isOverload,
  }) {
    return SocketInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      power: power ?? this.power,
      isOn: isOn ?? this.isOn,
      isOverload: isOverload ?? this.isOverload,
    );
  }
  
  @override
  List<Object?> get props => [id, name, power, isOn, isOverload];
}
