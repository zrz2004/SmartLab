/// API 端点定义
class ApiEndpoints {
  ApiEndpoints._();

  // ==================== 认证 ====================
  
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String profile = '/auth/me';
  static const String pendingRegistrations = '/auth/pending';
  
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
  static String acknowledgeAlert(String alertId) => '/alerts/$alertId/acknowledge';
  
  // ==================== 实验室管理 ====================
  
  static const String labs = '/labs';
  static const String buildings = '/buildings';
  static const String accessibleLabs = '/labs/accessible';
  static const String selectLab = '/labs/select';
  static String labContext(String labId) => '/labs/$labId/context';
  static String labReminderSettings(String labId) => '/labs/$labId/reminder-settings';
  
  // ==================== 用户管理 ====================
  
  static const String users = '/users';
  static const String roles = '/roles';
  static const String permissionsMe = '/permissions/me';

  // ==================== 媒体与 AI ====================

  static const String mediaUpload = '/media/upload';
  static const String aiInspections = '/ai-inspections';
  static const String latestAiInspection = '/ai-inspections/latest';
  
  // ==================== 报表 ====================
  
  static const String reports = '/reports';
  static const String energyReport = '/reports/energy';
  static const String complianceReport = '/reports/compliance';
}
