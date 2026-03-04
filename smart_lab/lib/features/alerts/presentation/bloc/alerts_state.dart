part of 'alerts_bloc.dart';

enum AlertsStatus { initial, loading, loaded, error }

class AlertsState extends Equatable {
  final AlertsStatus status;
  final List<Alert> alerts;
  final List<Alert> filteredAlerts;
  final AlertLevel? selectedLevel;
  final String? errorMessage;
  
  const AlertsState({
    this.status = AlertsStatus.initial,
    this.alerts = const [],
    this.filteredAlerts = const [],
    this.selectedLevel,
    this.errorMessage,
  });
  
  AlertsState copyWith({
    AlertsStatus? status,
    List<Alert>? alerts,
    List<Alert>? filteredAlerts,
    AlertLevel? selectedLevel,
    String? errorMessage,
  }) {
    return AlertsState(
      status: status ?? this.status,
      alerts: alerts ?? this.alerts,
      filteredAlerts: filteredAlerts ?? this.filteredAlerts,
      selectedLevel: selectedLevel,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  /// 未确认告警数量
  int get unacknowledgedCount {
    return alerts.where((a) => !a.isAcknowledged).length;
  }
  
  /// 严重告警数量
  int get criticalCount {
    return alerts.where((a) => a.level == AlertLevel.critical && !a.isAcknowledged).length;
  }
  
  /// 按级别统计
  Map<AlertLevel, int> get countByLevel {
    final counts = <AlertLevel, int>{};
    for (final alert in alerts) {
      counts[alert.level] = (counts[alert.level] ?? 0) + 1;
    }
    return counts;
  }
  
  @override
  List<Object?> get props => [
    status,
    alerts,
    filteredAlerts,
    selectedLevel,
  ];
}
