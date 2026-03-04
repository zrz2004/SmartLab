part of 'alerts_bloc.dart';

sealed class AlertsEvent extends Equatable {
  const AlertsEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadAlerts extends AlertsEvent {}

class AlertReceived extends AlertsEvent {
  final Alert alert;
  
  const AlertReceived(this.alert);
  
  @override
  List<Object?> get props => [alert];
}

class AcknowledgeAlert extends AlertsEvent {
  final String alertId;
  
  const AcknowledgeAlert(this.alertId);
  
  @override
  List<Object?> get props => [alertId];
}

class FilterAlerts extends AlertsEvent {
  final AlertLevel? level;
  
  const FilterAlerts(this.level);
  
  @override
  List<Object?> get props => [level];
}

class ClearAllAlerts extends AlertsEvent {}
