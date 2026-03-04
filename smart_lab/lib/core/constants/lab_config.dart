/// 实验室配置常量
/// 
/// 定义信息科学与技术学院的两个实验室配置
/// - 院楼806
/// - 西学楼一楼新信科实验室
class LabConfig {
  LabConfig._();

  // ==================== 实验室定义 ====================
  
  /// 实验室列表
  static const List<LabInfo> labs = [
    LabInfo(
      id: 'lab_yuanlou_806',
      name: '院楼806',
      buildingId: 'building_yuanlou',
      buildingName: '信息科学与技术学院院楼',
      floor: '8F',
      roomNumber: '806',
      type: 'computer',
      description: '信息科学与技术学院计算机实验室',
      areaSqm: 120.0,
      capacity: 40,
    ),
    LabInfo(
      id: 'lab_xixue_xinke',
      name: '西学楼新信科实验室',
      buildingId: 'building_xixue',
      buildingName: '西学楼',
      floor: '1F',
      roomNumber: '101',
      type: 'electronics',
      description: '信息科学与技术学院新建电子实验室',
      areaSqm: 150.0,
      capacity: 50,
    ),
  ];

  /// 建筑物定义
  static const List<BuildingInfo> buildings = [
    BuildingInfo(
      id: 'building_yuanlou',
      name: '信息科学与技术学院院楼',
      code: 'YUANLOU',
      floors: 12,
    ),
    BuildingInfo(
      id: 'building_xixue',
      name: '西学楼',
      code: 'XIXUE',
      floors: 5,
    ),
  ];

  // ==================== 院楼806 设备配置 ====================
  
  /// 院楼806 设备列表
  static const List<DeviceInfo> yuanlou806Devices = [
    // 环境传感器
    DeviceInfo(
      id: 'yl806_env_01',
      name: '环境传感器-主',
      type: 'environmentSensor',
      position: '房间中央天花板',
      mqttDeviceId: 'env_01',
    ),
    // 电源监测
    DeviceInfo(
      id: 'yl806_pwr_01',
      name: '总电源监测模块',
      type: 'powerMonitor',
      position: '配电箱',
      mqttDeviceId: 'pwr_01',
    ),
    // 智能插座
    DeviceInfo(
      id: 'yl806_sock_01',
      name: '服务器机柜插座',
      type: 'smartSocket',
      position: '机房区域',
      mqttDeviceId: 'sock_01',
    ),
    DeviceInfo(
      id: 'yl806_sock_02',
      name: '教师工作台插座',
      type: 'smartSocket',
      position: '教师区',
      mqttDeviceId: 'sock_02',
    ),
    DeviceInfo(
      id: 'yl806_sock_03',
      name: '学生电脑区A插座',
      type: 'smartSocket',
      position: '学生区A',
      mqttDeviceId: 'sock_03',
    ),
    DeviceInfo(
      id: 'yl806_sock_04',
      name: '学生电脑区B插座',
      type: 'smartSocket',
      position: '学生区B',
      mqttDeviceId: 'sock_04',
    ),
    // 门磁传感器
    DeviceInfo(
      id: 'yl806_door_01',
      name: '实验室正门',
      type: 'doorSensor',
      position: '正门',
      mqttDeviceId: 'door_01',
    ),
    // 窗磁传感器
    DeviceInfo(
      id: 'yl806_win_01',
      name: '南侧窗户',
      type: 'windowSensor',
      position: '南墙',
      mqttDeviceId: 'win_01',
    ),
    DeviceInfo(
      id: 'yl806_win_02',
      name: '北侧窗户',
      type: 'windowSensor',
      position: '北墙',
      mqttDeviceId: 'win_02',
    ),
  ];

  // ==================== 西学楼新信科实验室 设备配置 ====================
  
  /// 西学楼新信科实验室 设备列表
  static const List<DeviceInfo> xixueXinkeDevices = [
    // 环境传感器
    DeviceInfo(
      id: 'xx_env_01',
      name: '环境传感器-东区',
      type: 'environmentSensor',
      position: '东侧天花板',
      mqttDeviceId: 'env_01',
    ),
    DeviceInfo(
      id: 'xx_env_02',
      name: '环境传感器-西区',
      type: 'environmentSensor',
      position: '西侧天花板',
      mqttDeviceId: 'env_02',
    ),
    // 电源监测
    DeviceInfo(
      id: 'xx_pwr_01',
      name: '总电源监测模块',
      type: 'powerMonitor',
      position: '配电箱',
      mqttDeviceId: 'pwr_01',
    ),
    // 智能插座
    DeviceInfo(
      id: 'xx_sock_01',
      name: '实验台A区插座',
      type: 'smartSocket',
      position: '实验台A',
      mqttDeviceId: 'sock_01',
    ),
    DeviceInfo(
      id: 'xx_sock_02',
      name: '实验台B区插座',
      type: 'smartSocket',
      position: '实验台B',
      mqttDeviceId: 'sock_02',
    ),
    DeviceInfo(
      id: 'xx_sock_03',
      name: '仪器设备区插座',
      type: 'smartSocket',
      position: '仪器区',
      mqttDeviceId: 'sock_03',
    ),
    DeviceInfo(
      id: 'xx_sock_04',
      name: '通风设备插座',
      type: 'smartSocket',
      position: '通风区',
      mqttDeviceId: 'sock_04',
    ),
    // 水浸传感器
    DeviceInfo(
      id: 'xx_water_01',
      name: '水槽区水浸传感器',
      type: 'waterSensor',
      position: '水槽下方',
      mqttDeviceId: 'water_01',
    ),
    // 门磁传感器
    DeviceInfo(
      id: 'xx_door_01',
      name: '实验室正门',
      type: 'doorSensor',
      position: '正门',
      mqttDeviceId: 'door_01',
    ),
    DeviceInfo(
      id: 'xx_door_02',
      name: '应急出口',
      type: 'doorSensor',
      position: '后门',
      mqttDeviceId: 'door_02',
    ),
    // 窗磁传感器
    DeviceInfo(
      id: 'xx_win_01',
      name: '通风窗1',
      type: 'windowSensor',
      position: '东墙',
      mqttDeviceId: 'win_01',
    ),
    DeviceInfo(
      id: 'xx_win_02',
      name: '通风窗2',
      type: 'windowSensor',
      position: '西墙',
      mqttDeviceId: 'win_02',
    ),
  ];

  // ==================== 辅助方法 ====================

  /// 根据实验室ID获取设备列表
  static List<DeviceInfo> getDevicesByLabId(String labId) {
    switch (labId) {
      case 'lab_yuanlou_806':
        return yuanlou806Devices;
      case 'lab_xixue_xinke':
        return xixueXinkeDevices;
      default:
        return [];
    }
  }

  /// 获取实验室信息
  static LabInfo? getLabById(String labId) {
    try {
      return labs.firstWhere((lab) => lab.id == labId);
    } catch (_) {
      return null;
    }
  }

  /// 获取默认实验室（院楼806）
  static LabInfo get defaultLab => labs.first;
}

/// 实验室信息
class LabInfo {
  final String id;
  final String name;
  final String buildingId;
  final String buildingName;
  final String floor;
  final String roomNumber;
  final String type;
  final String? description;
  final double? areaSqm;
  final int? capacity;

  const LabInfo({
    required this.id,
    required this.name,
    required this.buildingId,
    required this.buildingName,
    required this.floor,
    required this.roomNumber,
    required this.type,
    this.description,
    this.areaSqm,
    this.capacity,
  });

  /// 获取完整位置描述
  String get fullLocation => '$buildingName $floor $roomNumber';
  
  /// 获取MQTT主题前缀
  String get mqttTopicPrefix => 'lab/$buildingId/$roomNumber';
}

/// 建筑物信息
class BuildingInfo {
  final String id;
  final String name;
  final String code;
  final int floors;

  const BuildingInfo({
    required this.id,
    required this.name,
    required this.code,
    required this.floors,
  });
}

/// 设备信息
class DeviceInfo {
  final String id;
  final String name;
  final String type;
  final String position;
  final String mqttDeviceId;

  const DeviceInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    required this.mqttDeviceId,
  });
}
