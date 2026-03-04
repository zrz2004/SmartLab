/// API 端点定义
class ApiEndpoints {
  ApiEndpoints._();

  // ==================== 认证 ====================
  
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String profile = '/auth/profile';
  
  // ==================== 设备管理 ====================
  
  static const String devices = '/devices';
  static const String controlSwitch = '/control/switch';
  
  // ==================== 遥测数据 ====================
  
  static const String telemetryHistory = '/telemetry/history';
  static const String telemetryLatest = '/telemetry/latest';
  
  // ==================== 危化品管理 ====================
  
  static const String chemicalInventory = '/chemicals/inventory';
  static const String chemicalCabinets = '/chemicals/cabinets';
  static const String chemicalLogs = '/chemicals/logs';
  
  // ==================== 报警管理 ====================
  
  static const String alerts = '/alerts';
  static const String alertsStatistics = '/alerts/statistics';
  
  // ==================== 实验室管理 ====================
  
  static const String labs = '/labs';
  static const String buildings = '/buildings';
  
  // ==================== 用户管理 ====================
  
  static const String users = '/users';
  static const String roles = '/roles';
  
  // ==================== 报表 ====================
  
  static const String reports = '/reports';
  static const String energyReport = '/reports/energy';
  static const String complianceReport = '/reports/compliance';
}
