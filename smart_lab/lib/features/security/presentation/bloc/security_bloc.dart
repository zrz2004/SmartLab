import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/services/mqtt_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/mock_data_provider.dart';
import '../../../dashboard/domain/entities/sensor_data.dart';

part 'security_event.dart';
part 'security_state.dart';

/// 安防管理 BLoC (水路 + 门窗)
class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  final MqttService mqttService;
  final ApiService apiService;
  StreamSubscription<SensorData>? _subscription;
  
  SecurityBloc({
    required this.mqttService,
    required this.apiService,
  }) : super(const SecurityState()) {
    on<LoadSecurityData>(_onLoadSecurityData);
    on<SecurityDataReceived>(_onSecurityDataReceived);
    on<ToggleWaterValve>(_onToggleWaterValve);
    on<ToggleWindow>(_onToggleWindow);
    on<ToggleDoor>(_onToggleDoor);
    
    _subscribeToData();
  }
  
  void _subscribeToData() {
    _subscription = mqttService.sensorDataStream
        .where((data) => 
            data.deviceType == 'water' || 
            data.deviceType == 'security')
        .listen((data) {
      add(SecurityDataReceived(data));
    });
  }
  
  void _onLoadSecurityData(
    LoadSecurityData event,
    Emitter<SecurityState> emit,
  ) {
    emit(state.copyWith(status: SecurityStatus.loading));
    
    // 根据当前实验室加载数据
    final currentLab = MockDataProvider.currentLab;
    
    emit(state.copyWith(
      status: SecurityStatus.loaded,
      // 水路监测 (只有西学楼新信科实验室有水浸传感器)
      hasWaterSensor: MockDataProvider.hasWaterSensor(),
      mainValveOpen: MockDataProvider.hasWaterSensor(),
      waterLeakDetected: MockDataProvider.isWaterLeakDetected(),
      waterLeakLevel: MockDataProvider.getWaterLeakLevel(),
      // 门窗状态
      doors: MockDataProvider.getDoorData(),
      windows: MockDataProvider.getWindowData(),
      labName: currentLab.name,
    ));
  }
  
  void _onSecurityDataReceived(
    SecurityDataReceived event,
    Emitter<SecurityState> emit,
  ) {
    final data = event.data;
    
    if (data.deviceType == 'water') {
      final waterLevel = data.getValue<num>('water_leak_level')?.toDouble();
      emit(state.copyWith(
        waterLeakDetected: waterLevel != null && waterLevel > 0,
        waterLeakLevel: waterLevel ?? 0,
        lastUpdateTime: DateTime.now(),
      ));
    }
  }
  
  Future<void> _onToggleWaterValve(
    ToggleWaterValve event,
    Emitter<SecurityState> emit,
  ) async {
    emit(state.copyWith(isControlling: true));
    
    try {
      final success = await mqttService.publishCommand(
        buildingId: 'building_1',
        roomId: 'room_302',
        deviceType: 'water',
        deviceId: 'main_valve',
        command: {'action': event.turnOn ? 'OPEN' : 'CLOSE'},
      );
      
      if (success) {
        emit(state.copyWith(
          mainValveOpen: event.turnOn,
          isControlling: false,
        ));
      } else {
        emit(state.copyWith(
          isControlling: false,
          errorMessage: '控制指令发送失败',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isControlling: false,
        errorMessage: e.toString(),
      ));
    }
  }
  
  Future<void> _onToggleWindow(
    ToggleWindow event,
    Emitter<SecurityState> emit,
  ) async {
    final updatedWindows = state.windows.map((window) {
      if (window.id == event.windowId) {
        return window.copyWith(
          isOpen: event.open,
          openAngle: event.open ? 45 : 0,
        );
      }
      return window;
    }).toList();
    
    emit(state.copyWith(windows: updatedWindows));
  }
  
  Future<void> _onToggleDoor(
    ToggleDoor event,
    Emitter<SecurityState> emit,
  ) async {
    final updatedDoors = state.doors.map((door) {
      if (door.id == event.doorId) {
        return door.copyWith(isLocked: event.lock);
      }
      return door;
    }).toList();
    
    emit(state.copyWith(doors: updatedDoors));
  }
  
  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
