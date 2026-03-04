part of 'security_bloc.dart';

enum SecurityStatus { initial, loading, loaded, error }

class SecurityState extends Equatable {
  final SecurityStatus status;
  
  // 实验室信息
  final String labName;
  
  // 水路监测
  final bool hasWaterSensor;
  final bool mainValveOpen;
  final bool waterLeakDetected;
  final double waterLeakLevel;
  
  // 门窗状态
  final List<DoorInfo> doors;
  final List<WindowInfo> windows;
  
  final bool isControlling;
  final DateTime? lastUpdateTime;
  final String? errorMessage;
  
  const SecurityState({
    this.status = SecurityStatus.initial,
    this.labName = '',
    this.hasWaterSensor = false,
    this.mainValveOpen = true,
    this.waterLeakDetected = false,
    this.waterLeakLevel = 0,
    this.doors = const [],
    this.windows = const [],
    this.isControlling = false,
    this.lastUpdateTime,
    this.errorMessage,
  });
  
  SecurityState copyWith({
    SecurityStatus? status,
    String? labName,
    bool? hasWaterSensor,
    bool? mainValveOpen,
    bool? waterLeakDetected,
    double? waterLeakLevel,
    List<DoorInfo>? doors,
    List<WindowInfo>? windows,
    bool? isControlling,
    DateTime? lastUpdateTime,
    String? errorMessage,
  }) {
    return SecurityState(
      status: status ?? this.status,
      labName: labName ?? this.labName,
      hasWaterSensor: hasWaterSensor ?? this.hasWaterSensor,
      mainValveOpen: mainValveOpen ?? this.mainValveOpen,
      waterLeakDetected: waterLeakDetected ?? this.waterLeakDetected,
      waterLeakLevel: waterLeakLevel ?? this.waterLeakLevel,
      doors: doors ?? this.doors,
      windows: windows ?? this.windows,
      isControlling: isControlling ?? this.isControlling,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  List<Object?> get props => [
    status,
    labName,
    hasWaterSensor,
    mainValveOpen,
    waterLeakDetected,
    waterLeakLevel,
    doors,
    windows,
    isControlling,
    lastUpdateTime,
  ];
}

/// 门信息
class DoorInfo extends Equatable {
  final String id;
  final String name;
  final bool isOpen;
  final bool isLocked;
  final bool hasCard;
  
  const DoorInfo({
    required this.id,
    required this.name,
    required this.isOpen,
    required this.isLocked,
    required this.hasCard,
  });
  
  DoorInfo copyWith({
    String? id,
    String? name,
    bool? isOpen,
    bool? isLocked,
    bool? hasCard,
  }) {
    return DoorInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      isOpen: isOpen ?? this.isOpen,
      isLocked: isLocked ?? this.isLocked,
      hasCard: hasCard ?? this.hasCard,
    );
  }
  
  @override
  List<Object?> get props => [id, name, isOpen, isLocked, hasCard];
}

/// 窗户信息
class WindowInfo extends Equatable {
  final String id;
  final String name;
  final bool isOpen;
  final int openAngle;
  
  const WindowInfo({
    required this.id,
    required this.name,
    required this.isOpen,
    required this.openAngle,
  });
  
  WindowInfo copyWith({
    String? id,
    String? name,
    bool? isOpen,
    int? openAngle,
  }) {
    return WindowInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      isOpen: isOpen ?? this.isOpen,
      openAngle: openAngle ?? this.openAngle,
    );
  }
  
  @override
  List<Object?> get props => [id, name, isOpen, openAngle];
}
