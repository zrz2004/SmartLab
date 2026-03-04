/// MQTT 主题定义
/// 
/// 遵循主题层级设计:
/// lab/{buildingId}/{roomId}/{deviceType}/{deviceId}/{messageType}
class MqttTopics {
  MqttTopics._();

  // ==================== 通配符订阅 ====================
  
  /// 订阅所有遥测数据
  static const String telemetryWildcard = 'lab/+/+/+/+/telemetry';
  
  /// 订阅所有报警事件
  static const String alertWildcard = 'lab/+/+/+/+/alert';
  
  /// 订阅所有设备状态
  static const String statusWildcard = 'lab/+/+/+/+/status';
  
  // ==================== 设备类型 ====================
  
  /// 环境传感器
  static const String deviceTypeEnvironment = 'environment';
  
  /// 电源设备
  static const String deviceTypePower = 'power';
  
  /// 水路设备
  static const String deviceTypeWater = 'water';
  
  /// 门窗传感器
  static const String deviceTypeSecurity = 'security';
  
  /// 危化品柜
  static const String deviceTypeChemical = 'chemical';
  
  // ==================== 主题构建方法 ====================
  
  /// 构建遥测数据主题
  static String telemetry({
    required String buildingId,
    required String roomId,
    required String deviceType,
    required String deviceId,
  }) {
    return 'lab/$buildingId/$roomId/$deviceType/$deviceId/telemetry';
  }
  
  /// 构建报警主题
  static String alert({
    required String buildingId,
    required String roomId,
    required String deviceType,
    required String deviceId,
  }) {
    return 'lab/$buildingId/$roomId/$deviceType/$deviceId/alert';
  }
  
  /// 构建控制指令主题
  static String command({
    required String buildingId,
    required String roomId,
    required String deviceType,
    required String deviceId,
  }) {
    return 'lab/$buildingId/$roomId/$deviceType/$deviceId/cmd';
  }
  
  /// 构建设备状态主题
  static String status({
    required String buildingId,
    required String roomId,
    required String deviceType,
    required String deviceId,
  }) {
    return 'lab/$buildingId/$roomId/$deviceType/$deviceId/status';
  }
  
  /// 订阅特定实验室的所有数据
  static String labWildcard({
    required String buildingId,
    required String roomId,
  }) {
    return 'lab/$buildingId/$roomId/+/+/+';
  }
}
