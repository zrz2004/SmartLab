part of 'power_bloc.dart';

sealed class PowerEvent extends Equatable {
  const PowerEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadPowerData extends PowerEvent {}

class PowerDataReceived extends PowerEvent {
  final SensorData data;
  
  const PowerDataReceived(this.data);
  
  @override
  List<Object?> get props => [data];
}

class ToggleMainPower extends PowerEvent {
  final bool turnOn;
  
  const ToggleMainPower(this.turnOn);
  
  @override
  List<Object?> get props => [turnOn];
}

class ToggleSocket extends PowerEvent {
  final String socketId;
  final bool turnOn;
  
  const ToggleSocket(this.socketId, this.turnOn);
  
  @override
  List<Object?> get props => [socketId, turnOn];
}
