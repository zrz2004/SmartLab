part of 'environment_bloc.dart';

sealed class EnvironmentEvent extends Equatable {
  const EnvironmentEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadEnvironmentData extends EnvironmentEvent {}

class EnvironmentDataReceived extends EnvironmentEvent {
  final SensorData data;
  
  const EnvironmentDataReceived(this.data);
  
  @override
  List<Object?> get props => [data];
}

class SetAlarmThreshold extends EnvironmentEvent {
  final String type;
  final double warningValue;
  final double criticalValue;
  
  const SetAlarmThreshold({
    required this.type,
    required this.warningValue,
    required this.criticalValue,
  });
  
  @override
  List<Object?> get props => [type, warningValue, criticalValue];
}
