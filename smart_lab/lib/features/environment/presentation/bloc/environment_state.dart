part of 'environment_bloc.dart';

enum EnvironmentStatus { initial, loading, loaded, error }

class EnvironmentState extends Equatable {
  final EnvironmentStatus status;
  final double? currentTemperature;
  final double? currentHumidity;
  final double? currentVoc;
  final double? currentPm25;
  final SafetyLevel temperatureLevel;
  final SafetyLevel humidityLevel;
  final SafetyLevel vocLevel;
  final List<FlSpot> temperatureHistory;
  final List<FlSpot> humidityHistory;
  final List<FlSpot> vocHistory;
  final DateTime? lastUpdateTime;
  final String? errorMessage;
  
  const EnvironmentState({
    this.status = EnvironmentStatus.initial,
    this.currentTemperature,
    this.currentHumidity,
    this.currentVoc,
    this.currentPm25,
    this.temperatureLevel = SafetyLevel.normal,
    this.humidityLevel = SafetyLevel.normal,
    this.vocLevel = SafetyLevel.normal,
    this.temperatureHistory = const [],
    this.humidityHistory = const [],
    this.vocHistory = const [],
    this.lastUpdateTime,
    this.errorMessage,
  });
  
  EnvironmentState copyWith({
    EnvironmentStatus? status,
    double? currentTemperature,
    double? currentHumidity,
    double? currentVoc,
    double? currentPm25,
    SafetyLevel? temperatureLevel,
    SafetyLevel? humidityLevel,
    SafetyLevel? vocLevel,
    List<FlSpot>? temperatureHistory,
    List<FlSpot>? humidityHistory,
    List<FlSpot>? vocHistory,
    DateTime? lastUpdateTime,
    String? errorMessage,
  }) {
    return EnvironmentState(
      status: status ?? this.status,
      currentTemperature: currentTemperature ?? this.currentTemperature,
      currentHumidity: currentHumidity ?? this.currentHumidity,
      currentVoc: currentVoc ?? this.currentVoc,
      currentPm25: currentPm25 ?? this.currentPm25,
      temperatureLevel: temperatureLevel ?? this.temperatureLevel,
      humidityLevel: humidityLevel ?? this.humidityLevel,
      vocLevel: vocLevel ?? this.vocLevel,
      temperatureHistory: temperatureHistory ?? this.temperatureHistory,
      humidityHistory: humidityHistory ?? this.humidityHistory,
      vocHistory: vocHistory ?? this.vocHistory,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  List<Object?> get props => [
    status,
    currentTemperature,
    currentHumidity,
    currentVoc,
    temperatureLevel,
    humidityLevel,
    vocLevel,
    temperatureHistory,
    humidityHistory,
    vocHistory,
    lastUpdateTime,
  ];
}
