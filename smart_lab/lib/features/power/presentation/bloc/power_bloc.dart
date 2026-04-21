import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/mock_data_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/mqtt_service.dart';
import '../../../dashboard/domain/entities/sensor_data.dart';

part 'power_event.dart';
part 'power_state.dart';

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

    _subscription = mqttService.sensorDataStream
        .where((data) => data.deviceType == 'power')
        .listen((data) => add(PowerDataReceived(data)));
  }

  void _onLoadPowerData(
    LoadPowerData event,
    Emitter<PowerState> emit,
  ) {
    final currentLab = MockDataProvider.currentLab;

    emit(
      state.copyWith(
        status: PowerStatus.loaded,
        isMainPowerOn: true,
        currentVoltage: MockDataProvider.getVoltage(),
        currentPower: MockDataProvider.getTotalPower(),
        leakageCurrent: MockDataProvider.getLeakageCurrent(),
        sockets: MockDataProvider.getSocketData(),
        labName: currentLab.name,
      ),
    );
  }

  void _onPowerDataReceived(
    PowerDataReceived event,
    Emitter<PowerState> emit,
  ) {
    emit(
      state.copyWith(
        currentVoltage: event.data.voltage,
        currentPower: event.data.power,
        leakageCurrent: event.data.leakageCurrent,
        lastUpdateTime: DateTime.now(),
      ),
    );
  }

  Future<void> _onToggleMainPower(
    ToggleMainPower event,
    Emitter<PowerState> emit,
  ) async {
    emit(state.copyWith(isControlling: true, errorMessage: null));

    try {
      final currentLab = MockDataProvider.currentLab;
      final success = await mqttService.publishCommand(
        buildingId: currentLab.buildingId,
        roomId: currentLab.roomNumber,
        deviceType: 'power',
        deviceId: 'main_breaker',
        command: {'action': event.turnOn ? 'ON' : 'OFF'},
      );

      emit(
        state.copyWith(
          isMainPowerOn: success ? event.turnOn : state.isMainPowerOn,
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

  Future<void> _onToggleSocket(
    ToggleSocket event,
    Emitter<PowerState> emit,
  ) async {
    final updatedSockets = state.sockets.map((socket) {
      if (socket.id == event.socketId) {
        return socket.copyWith(isOn: event.turnOn);
      }
      return socket;
    }).toList();

    emit(state.copyWith(sockets: updatedSockets));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
