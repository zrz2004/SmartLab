class LabConfig {
  LabConfig._();

  static const List<LabInfo> labs = [
    LabInfo(
      id: 'lab_yuanlou_806',
      name: '院楼806实验室',
      englishName: 'Yuanlou 806 Lab',
      buildingId: 'building_yuanlou',
      buildingName: '信息科学楼',
      englishBuildingName: 'School of Information Science Building',
      floor: '8F',
      roomNumber: '806',
      type: 'computer',
      description: '计算机与信息安全实验室',
      areaSqm: 120.0,
      capacity: 40,
    ),
    LabInfo(
      id: 'lab_xixue_xinke',
      name: '西学楼一楼信科实验室',
      englishName: 'Xixue Information Science Lab',
      buildingId: 'building_xixue',
      buildingName: '西学楼',
      englishBuildingName: 'Xixue Building',
      floor: '1F',
      roomNumber: '101',
      type: 'electronics',
      description: '信科综合实验室',
      areaSqm: 150.0,
      capacity: 50,
    ),
  ];

  static const List<BuildingInfo> buildings = [
    BuildingInfo(
      id: 'building_yuanlou',
      name: '信息科学楼',
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

  static const List<DeviceInfo> yuanlou806Devices = [
    DeviceInfo(
      id: 'yl806_env_01',
      name: '环境传感器 1',
      type: 'environmentSensor',
      position: '天花板中央',
      mqttDeviceId: 'env_01',
    ),
    DeviceInfo(
      id: 'yl806_pwr_01',
      name: '总电源监测',
      type: 'powerMonitor',
      position: '配电柜',
      mqttDeviceId: 'pwr_01',
    ),
    DeviceInfo(
      id: 'yl806_sock_01',
      name: '服务器插座',
      type: 'smartSocket',
      position: '服务器区域',
      mqttDeviceId: 'sock_01',
    ),
    DeviceInfo(
      id: 'yl806_sock_02',
      name: '教师工位插座',
      type: 'smartSocket',
      position: '教师工位',
      mqttDeviceId: 'sock_02',
    ),
    DeviceInfo(
      id: 'yl806_sock_03',
      name: '学生区A插座',
      type: 'smartSocket',
      position: '学生区 A',
      mqttDeviceId: 'sock_03',
    ),
    DeviceInfo(
      id: 'yl806_sock_04',
      name: '学生区B插座',
      type: 'smartSocket',
      position: '学生区 B',
      mqttDeviceId: 'sock_04',
    ),
    DeviceInfo(
      id: 'yl806_door_01',
      name: '主门',
      type: 'doorSensor',
      position: '前门',
      mqttDeviceId: 'door_01',
    ),
    DeviceInfo(
      id: 'yl806_win_01',
      name: '南侧窗户',
      type: 'windowSensor',
      position: '南侧墙面',
      mqttDeviceId: 'win_01',
    ),
    DeviceInfo(
      id: 'yl806_win_02',
      name: '北侧窗户',
      type: 'windowSensor',
      position: '北侧墙面',
      mqttDeviceId: 'win_02',
    ),
  ];

  static const List<DeviceInfo> xixueXinkeDevices = [
    DeviceInfo(
      id: 'xx_env_01',
      name: '东侧环境传感器',
      type: 'environmentSensor',
      position: '东侧天花板',
      mqttDeviceId: 'env_01',
    ),
    DeviceInfo(
      id: 'xx_env_02',
      name: '西侧环境传感器',
      type: 'environmentSensor',
      position: '西侧天花板',
      mqttDeviceId: 'env_02',
    ),
    DeviceInfo(
      id: 'xx_pwr_01',
      name: '总电源监测',
      type: 'powerMonitor',
      position: '配电柜',
      mqttDeviceId: 'pwr_01',
    ),
    DeviceInfo(
      id: 'xx_sock_01',
      name: '实验台A插座',
      type: 'smartSocket',
      position: '实验台 A',
      mqttDeviceId: 'sock_01',
    ),
    DeviceInfo(
      id: 'xx_sock_02',
      name: '实验台B插座',
      type: 'smartSocket',
      position: '实验台 B',
      mqttDeviceId: 'sock_02',
    ),
    DeviceInfo(
      id: 'xx_sock_03',
      name: '仪器区插座',
      type: 'smartSocket',
      position: '仪器区',
      mqttDeviceId: 'sock_03',
    ),
    DeviceInfo(
      id: 'xx_sock_04',
      name: '通风设备插座',
      type: 'smartSocket',
      position: '通风设备区',
      mqttDeviceId: 'sock_04',
    ),
    DeviceInfo(
      id: 'xx_water_01',
      name: '水路传感器',
      type: 'waterSensor',
      position: '水槽区域',
      mqttDeviceId: 'water_01',
    ),
    DeviceInfo(
      id: 'xx_door_01',
      name: '主门',
      type: 'doorSensor',
      position: '前门',
      mqttDeviceId: 'door_01',
    ),
    DeviceInfo(
      id: 'xx_door_02',
      name: '应急门',
      type: 'doorSensor',
      position: '后门',
      mqttDeviceId: 'door_02',
    ),
    DeviceInfo(
      id: 'xx_win_01',
      name: '东侧窗户',
      type: 'windowSensor',
      position: '东侧墙面',
      mqttDeviceId: 'win_01',
    ),
    DeviceInfo(
      id: 'xx_win_02',
      name: '西侧窗户',
      type: 'windowSensor',
      position: '西侧墙面',
      mqttDeviceId: 'win_02',
    ),
  ];

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

  static LabInfo? getLabById(String labId) {
    try {
      return labs.firstWhere((lab) => lab.id == labId);
    } catch (_) {
      return null;
    }
  }

  static BuildingInfo? getBuilding(String buildingId) {
    try {
      return buildings.firstWhere((building) => building.id == buildingId);
    } catch (_) {
      return null;
    }
  }

  static int getDeviceCountByType(String labId, String deviceType) {
    return getDevicesByLabId(labId)
        .where((device) => device.type == deviceType)
        .length;
  }

  static LabInfo get defaultLab => labs.first;
}

class LabInfo {
  final String id;
  final String name;
  final String englishName;
  final String buildingId;
  final String buildingName;
  final String englishBuildingName;
  final String floor;
  final String roomNumber;
  final String type;
  final String? description;
  final double? areaSqm;
  final int? capacity;

  const LabInfo({
    required this.id,
    required this.name,
    required this.englishName,
    required this.buildingId,
    required this.buildingName,
    required this.englishBuildingName,
    required this.floor,
    required this.roomNumber,
    required this.type,
    this.description,
    this.areaSqm,
    this.capacity,
  });

  String get fullLocation => '$buildingName · $floor · $roomNumber';
  String get englishLocation => '$englishBuildingName · $floor · $roomNumber';
  String get mqttTopicPrefix => 'lab/$buildingId/$roomNumber';
}

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
