part of 'security_bloc.dart';

sealed class SecurityEvent extends Equatable {
  const SecurityEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadSecurityData extends SecurityEvent {}

class SecurityDataReceived extends SecurityEvent {
  final SensorData data;
  
  const SecurityDataReceived(this.data);
  
  @override
  List<Object?> get props => [data];
}

class ToggleWaterValve extends SecurityEvent {
  final bool turnOn;
  
  const ToggleWaterValve(this.turnOn);
  
  @override
  List<Object?> get props => [turnOn];
}

class ToggleWindow extends SecurityEvent {
  final String windowId;
  final bool open;
  
  const ToggleWindow(this.windowId, this.open);
  
  @override
  List<Object?> get props => [windowId, open];
}

class ToggleDoor extends SecurityEvent {
  final String doorId;
  final bool lock;
  
  const ToggleDoor(this.doorId, this.lock);
  
  @override
  List<Object?> get props => [doorId, lock];
}
