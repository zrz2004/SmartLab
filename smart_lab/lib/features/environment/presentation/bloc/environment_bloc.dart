import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/mock_data_provider.dart';
import '../../../../core/constants/safety_thresholds.dart';
import '../../../../core/services/mqtt_service.dart';
import '../../../dashboard/domain/entities/sensor_data.dart';

part 'environment_event.dart';
part 'environment_state.dart';

class EnvironmentBloc extends Bloc<EnvironmentEvent, EnvironmentState> {
  final MqttService mqttService;
  StreamSubscription<SensorData>? _subscription;
  final List<FlSpot> _temperatureHistory = [];
  final List<FlSpot> _humidityHistory = [];
  final List<FlSpot> _vocHistory = [];
  int _dataIndex = 0;

  EnvironmentBloc({
    required this.mqttService,
  }) : super(const EnvironmentState()) {
    on<LoadEnvironmentData>(_onLoadEnvironmentData);
    on<EnvironmentDataReceived>(_onEnvironmentDataReceived);
    on<SetAlarmThreshold>(_onSetAlarmThreshold);

    _subscription = mqttService.sensorDataStream
        .where((data) => data.deviceType == 'environment')
        .listen((data) => add(EnvironmentDataReceived(data)));
  }

  void _onLoadEnvironmentData(
    LoadEnvironmentData event,
    Emitter<EnvironmentState> emit,
  ) {
    _initMockData();

    final temperature = MockDataProvider.getTemperature();
    final humidity = MockDataProvider.getHumidity();
    final voc = MockDataProvider.getVocIndex();

    emit(
      state.copyWith(
        status: EnvironmentStatus.loaded,
        currentTemperature: temperature,
        currentHumidity: humidity,
        currentVoc: voc,
        currentPm25: MockDataProvider.getPm25(),
        temperatureLevel: SafetyThresholds.getTemperatureLevel(temperature),
        humidityLevel: SafetyThresholds.getHumidityLevel(humidity),
        vocLevel: SafetyThresholds.getVocLevel(voc),
        temperatureHistory: List.from(_temperatureHistory),
        humidityHistory: List.from(_humidityHistory),
        vocHistory: List.from(_vocHistory),
      ),
    );
  }

  void _initMockData() {
    _temperatureHistory.clear();
    _humidityHistory.clear();
    _vocHistory.clear();

    final baseTemp = MockDataProvider.getTemperature();
    final baseHumidity = MockDataProvider.getHumidity();
    final baseVoc = MockDataProvider.getVocIndex();

    for (var i = 0; i < 30; i++) {
      _temperatureHistory.add(FlSpot(i.toDouble(), baseTemp + (i % 5) * 0.25));
      _humidityHistory.add(FlSpot(i.toDouble(), baseHumidity + (i % 8) - 4));
      _vocHistory.add(FlSpot(i.toDouble(), baseVoc + (i % 10) * 6));
      _dataIndex = i + 1;
    }
  }

  void _onEnvironmentDataReceived(
    EnvironmentDataReceived event,
    Emitter<EnvironmentState> emit,
  ) {
    final data = event.data;

    if (data.temperature != null) {
      _temperatureHistory.add(FlSpot(_dataIndex.toDouble(), data.temperature!));
      if (_temperatureHistory.length > 60) _temperatureHistory.removeAt(0);
    }

    if (data.humidity != null) {
      _humidityHistory.add(FlSpot(_dataIndex.toDouble(), data.humidity!));
      if (_humidityHistory.length > 60) _humidityHistory.removeAt(0);
    }

    if (data.vocIndex != null) {
      _vocHistory.add(FlSpot(_dataIndex.toDouble(), data.vocIndex!));
      if (_vocHistory.length > 60) _vocHistory.removeAt(0);
    }

    _dataIndex++;

    emit(
      state.copyWith(
        currentTemperature: data.temperature,
        currentHumidity: data.humidity,
        currentVoc: data.vocIndex,
        currentPm25: data.pm25,
        temperatureLevel: SafetyThresholds.getTemperatureLevel(
          data.temperature ?? MockDataProvider.getTemperature(),
        ),
        humidityLevel: SafetyThresholds.getHumidityLevel(
          data.humidity ?? MockDataProvider.getHumidity(),
        ),
        vocLevel: SafetyThresholds.getVocLevel(
          data.vocIndex ?? MockDataProvider.getVocIndex(),
        ),
        temperatureHistory: List.from(_temperatureHistory),
        humidityHistory: List.from(_humidityHistory),
        vocHistory: List.from(_vocHistory),
        lastUpdateTime: DateTime.now(),
      ),
    );
  }

  void _onSetAlarmThreshold(
    SetAlarmThreshold event,
    Emitter<EnvironmentState> emit,
  ) {}

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
