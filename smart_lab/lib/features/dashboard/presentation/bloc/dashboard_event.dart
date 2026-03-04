part of 'dashboard_bloc.dart';

/// 仪表盘事件基类
sealed class DashboardEvent extends Equatable {
  const DashboardEvent();
  
  @override
  List<Object?> get props => [];
}

/// 加载仪表盘数据
class LoadDashboardData extends DashboardEvent {}

/// 收到传感器数据
class SensorDataReceived extends DashboardEvent {
  final SensorData data;
  
  const SensorDataReceived(this.data);
  
  @override
  List<Object?> get props => [data];
}

/// 收到报警
class AlertReceived extends DashboardEvent {
  final Alert alert;
  
  const AlertReceived(this.alert);
  
  @override
  List<Object?> get props => [alert];
}

/// MQTT 连接状态变化
class MqttConnectionChanged extends DashboardEvent {
  final bool isConnected;
  
  const MqttConnectionChanged(this.isConnected);
  
  @override
  List<Object?> get props => [isConnected];
}

/// 确认报警
class AcknowledgeAlert extends DashboardEvent {
  final String alertId;
  
  const AcknowledgeAlert(this.alertId);
  
  @override
  List<Object?> get props => [alertId];
}

/// 刷新仪表盘
class RefreshDashboard extends DashboardEvent {}
