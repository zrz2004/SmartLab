import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/mock_data_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/mqtt_service.dart';
import '../../../dashboard/domain/entities/sensor_data.dart';

part 'security_event.dart';
part 'security_state.dart';

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

    _subscription = mqttService.sensorDataStream
        .where((data) => data.deviceType == 'water' || data.deviceType == 'security')
        .listen((data) => add(SecurityDataReceived(data)));
  }

  void _onLoadSecurityData(
    LoadSecurityData event,
    Emitter<SecurityState> emit,
  ) {
    final currentLab = MockDataProvider.currentLab;

    emit(
      state.copyWith(
        status: SecurityStatus.loaded,
        hasWaterSensor: MockDataProvider.hasWaterSensor(),
        mainValveOpen: MockDataProvider.hasWaterSensor(),
        waterLeakDetected: MockDataProvider.isWaterLeakDetected(),
        waterLeakLevel: MockDataProvider.getWaterLeakLevel(),
        doors: MockDataProvider.getDoorData(),
        windows: MockDataProvider.getWindowData(),
        labName: currentLab.name,
      ),
    );
  }

  void _onSecurityDataReceived(
    SecurityDataReceived event,
    Emitter<SecurityState> emit,
  ) {
    final waterLevel = event.data.getValue<num>('water_leak_level')?.toDouble();
    if (waterLevel == null) return;

    emit(
      state.copyWith(
        waterLeakDetected: waterLevel > 0,
        waterLeakLevel: waterLevel,
        lastUpdateTime: DateTime.now(),
      ),
    );
  }

  Future<void> _onToggleWaterValve(
    ToggleWaterValve event,
    Emitter<SecurityState> emit,
  ) async {
    emit(state.copyWith(isControlling: true, errorMessage: null));

    try {
      final currentLab = MockDataProvider.currentLab;
      final success = await mqttService.publishCommand(
        buildingId: currentLab.buildingId,
        roomId: currentLab.roomNumber,
        deviceType: 'water',
        deviceId: 'main_valve',
        command: {'action': event.turnOn ? 'OPEN' : 'CLOSE'},
      );

      emit(
        state.copyWith(
          mainValveOpen: success ? event.turnOn : state.mainValveOpen,
          isControlling: false,
          errorMessage: success ? null : 'Control command failed',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isControlling: false,
          errorMessage: error.toString(),
        ),
      );
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
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
