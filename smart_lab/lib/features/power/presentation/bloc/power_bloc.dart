import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/services/mqtt_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/mock_data_provider.dart';
import '../../../dashboard/domain/entities/sensor_data.dart';

part 'power_event.dart';
part 'power_state.dart';

/// 电源管理 BLoC
class PowerBloc extends Bloc<PowerEvent, PowerState> {
  final MqttService mqttService;
  final ApiService apiService;
  StreamSubscription<SensorData>? _subscription;
  
  PowerBloc({
    required this.mqttService,
    required this.apiService,
  }) : super(const PowerState()) {
    on<LoadPowerData>(_onLoadPowerData);
    on<PowerDataReceived>(_onPowerDataReceived);
    on<ToggleMainPower>(_onToggleMainPower);
    on<ToggleSocket>(_onToggleSocket);
    
    _subscribeToData();
  }
  
  void _subscribeToData() {
    _subscription = mqttService.sensorDataStream
        .where((data) => data.deviceType == 'power')
        .listen((data) {
      add(PowerDataReceived(data));
    });
  }
  
  void _onLoadPowerData(
    LoadPowerData event,
    Emitter<PowerState> emit,
  ) {
    emit(state.copyWith(status: PowerStatus.loading));
    
    // 根据当前实验室加载数据
    final currentLab = MockDataProvider.currentLab;
    
    emit(state.copyWith(
      status: PowerStatus.loaded,
      isMainPowerOn: true,
      currentVoltage: MockDataProvider.getVoltage(),
      currentPower: MockDataProvider.getTotalPower(),
      leakageCurrent: MockDataProvider.getLeakageCurrent(),
      sockets: MockDataProvider.getSocketData(),
      labName: currentLab.name,
    ));
  }
  
  void _onPowerDataReceived(
    PowerDataReceived event,
    Emitter<PowerState> emit,
  ) {
    final data = event.data;
    emit(state.copyWith(
      currentVoltage: data.voltage,
      currentPower: data.power,
      leakageCurrent: data.leakageCurrent,
      lastUpdateTime: DateTime.now(),
    ));
  }
  
  Future<void> _onToggleMainPower(
    ToggleMainPower event,
    Emitter<PowerState> emit,
  ) async {
    emit(state.copyWith(isControlling: true));
    
    try {
      // 发送控制指令
      final success = await mqttService.publishCommand(
        buildingId: 'building_1',
        roomId: 'room_302',
        deviceType: 'power',
        deviceId: 'main_breaker',
        command: {'action': event.turnOn ? 'ON' : 'OFF'},
      );
      
      if (success) {
        emit(state.copyWith(
          isMainPowerOn: event.turnOn,
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
  
  Future<void> _onToggleSocket(
    ToggleSocket event,
    Emitter<PowerState> emit,
  ) async {
    // 更新插座状态
    final updatedSockets = state.sockets.map((socket) {
      if (socket.id == event.socketId) {
        return socket.copyWith(isOn: event.turnOn);
      }
      return socket;
    }).toList();
    
    emit(state.copyWith(sockets: updatedSockets));
  }
  
  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
