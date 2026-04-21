part of 'alerts_bloc.dart';

enum AlertsStatus { initial, loading, loaded, error }

const Object _alertsSelectedLevelSentinel = Object();
const Object _alertsErrorSentinel = Object();

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
    Object? selectedLevel = _alertsSelectedLevelSentinel,
    Object? errorMessage = _alertsErrorSentinel,
  }) {
    return AlertsState(
      status: status ?? this.status,
      alerts: alerts ?? this.alerts,
      filteredAlerts: filteredAlerts ?? this.filteredAlerts,
      selectedLevel: identical(selectedLevel, _alertsSelectedLevelSentinel)
          ? this.selectedLevel
          : selectedLevel as AlertLevel?,
      errorMessage: identical(errorMessage, _alertsErrorSentinel)
          ? this.errorMessage
          : errorMessage as String?,
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
