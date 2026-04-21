class LabConfig {
  LabConfig._();

  static const List<LabInfo> labs = [
    LabInfo(
      id: 'lab_yuanlou_806',
      name: 'Yuanlou 806',
      buildingId: 'building_yuanlou',
      buildingName: 'School of Information Science Building',
      floor: '8F',
      roomNumber: '806',
      type: 'computer',
      description: 'Computer lab',
      areaSqm: 120.0,
      capacity: 40,
    ),
    LabInfo(
      id: 'lab_xixue_xinke',
      name: 'Xixue Xinke Lab',
      buildingId: 'building_xixue',
      buildingName: 'Xixue Building',
      floor: '1F',
      roomNumber: '101',
      type: 'electronics',
      description: 'Electronics lab',
      areaSqm: 150.0,
      capacity: 50,
    ),
  ];

  static const List<BuildingInfo> buildings = [
    BuildingInfo(id: 'building_yuanlou', name: 'School of Information Science Building', code: 'YUANLOU', floors: 12),
    BuildingInfo(id: 'building_xixue', name: 'Xixue Building', code: 'XIXUE', floors: 5),
  ];

  static const List<DeviceInfo> yuanlou806Devices = [
    DeviceInfo(id: 'yl806_env_01', name: 'Env Sensor 1', type: 'environmentSensor', position: 'Ceiling center', mqttDeviceId: 'env_01'),
    DeviceInfo(id: 'yl806_pwr_01', name: 'Power Monitor', type: 'powerMonitor', position: 'Power cabinet', mqttDeviceId: 'pwr_01'),
    DeviceInfo(id: 'yl806_sock_01', name: 'Server Socket', type: 'smartSocket', position: 'Server area', mqttDeviceId: 'sock_01'),
    DeviceInfo(id: 'yl806_sock_02', name: 'Teacher Socket', type: 'smartSocket', position: 'Teacher desk', mqttDeviceId: 'sock_02'),
    DeviceInfo(id: 'yl806_sock_03', name: 'Student Zone A', type: 'smartSocket', position: 'Zone A', mqttDeviceId: 'sock_03'),
    DeviceInfo(id: 'yl806_sock_04', name: 'Student Zone B', type: 'smartSocket', position: 'Zone B', mqttDeviceId: 'sock_04'),
    DeviceInfo(id: 'yl806_door_01', name: 'Main Door', type: 'doorSensor', position: 'Front door', mqttDeviceId: 'door_01'),
    DeviceInfo(id: 'yl806_win_01', name: 'South Window', type: 'windowSensor', position: 'South wall', mqttDeviceId: 'win_01'),
    DeviceInfo(id: 'yl806_win_02', name: 'North Window', type: 'windowSensor', position: 'North wall', mqttDeviceId: 'win_02'),
  ];

  static const List<DeviceInfo> xixueXinkeDevices = [
    DeviceInfo(id: 'xx_env_01', name: 'Env Sensor East', type: 'environmentSensor', position: 'East ceiling', mqttDeviceId: 'env_01'),
    DeviceInfo(id: 'xx_env_02', name: 'Env Sensor West', type: 'environmentSensor', position: 'West ceiling', mqttDeviceId: 'env_02'),
    DeviceInfo(id: 'xx_pwr_01', name: 'Power Monitor', type: 'powerMonitor', position: 'Power cabinet', mqttDeviceId: 'pwr_01'),
    DeviceInfo(id: 'xx_sock_01', name: 'Bench A Socket', type: 'smartSocket', position: 'Bench A', mqttDeviceId: 'sock_01'),
    DeviceInfo(id: 'xx_sock_02', name: 'Bench B Socket', type: 'smartSocket', position: 'Bench B', mqttDeviceId: 'sock_02'),
    DeviceInfo(id: 'xx_sock_03', name: 'Instrument Socket', type: 'smartSocket', position: 'Instrument zone', mqttDeviceId: 'sock_03'),
    DeviceInfo(id: 'xx_sock_04', name: 'Ventilation Socket', type: 'smartSocket', position: 'Ventilation zone', mqttDeviceId: 'sock_04'),
    DeviceInfo(id: 'xx_water_01', name: 'Water Sensor', type: 'waterSensor', position: 'Sink area', mqttDeviceId: 'water_01'),
    DeviceInfo(id: 'xx_door_01', name: 'Main Door', type: 'doorSensor', position: 'Front door', mqttDeviceId: 'door_01'),
    DeviceInfo(id: 'xx_door_02', name: 'Emergency Exit', type: 'doorSensor', position: 'Back door', mqttDeviceId: 'door_02'),
    DeviceInfo(id: 'xx_win_01', name: 'East Window', type: 'windowSensor', position: 'East wall', mqttDeviceId: 'win_01'),
    DeviceInfo(id: 'xx_win_02', name: 'West Window', type: 'windowSensor', position: 'West wall', mqttDeviceId: 'win_02'),
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
    return getDevicesByLabId(labId).where((device) => device.type == deviceType).length;
  }

  static LabInfo get defaultLab => labs.first;
}

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

  String get fullLocation => '$buildingName $floor $roomNumber';
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
