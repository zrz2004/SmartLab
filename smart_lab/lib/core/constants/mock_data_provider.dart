import 'lab_config.dart';
import '../../features/power/presentation/bloc/power_bloc.dart';
import '../../features/security/presentation/bloc/security_bloc.dart';

/// 模拟数据提供者
/// 
/// 根据选中的实验室返回相应的模拟数据
/// 用于开发和测试阶段
class MockDataProvider {
  MockDataProvider._();

  // 当前选中的实验室ID
  static String _currentLabId = LabConfig.defaultLab.id;

  /// 获取当前实验室ID
  static String get currentLabId => _currentLabId;

  /// 设置当前实验室
  static void setCurrentLab(String labId) {
    _currentLabId = labId;
  }

  /// 获取当前实验室信息
  static LabInfo get currentLab => 
      LabConfig.getLabById(_currentLabId) ?? LabConfig.defaultLab;

  // ==================== 电源数据 ====================

  /// 获取电源插座数据
  static List<SocketInfo> getSocketData() {
    switch (_currentLabId) {
      case 'lab_yuanlou_806':
        return _yuanlou806Sockets;
      case 'lab_xixue_xinke':
        return _xixueXinkeSockets;
      default:
        return _yuanlou806Sockets;
    }
  }

  /// 院楼806 插座数据
  static const List<SocketInfo> _yuanlou806Sockets = [
    SocketInfo(
      id: 'yl806_sock_01',
      name: '服务器机柜',
      power: 650,
      isOn: true,
      isOverload: false,
    ),
    SocketInfo(
      id: 'yl806_sock_02',
      name: '教师工作台',
      power: 180,
      isOn: true,
      isOverload: false,
    ),
    SocketInfo(
      id: 'yl806_sock_03',
      name: '学生电脑区A',
      power: 420,
      isOn: true,
      isOverload: false,
    ),
    SocketInfo(
      id: 'yl806_sock_04',
      name: '学生电脑区B',
      power: 380,
      isOn: true,
      isOverload: false,
    ),
  ];

  /// 西学楼新信科实验室 插座数据
  static const List<SocketInfo> _xixueXinkeSockets = [
    SocketInfo(
      id: 'xx_sock_01',
      name: '实验台A区',
      power: 320,
      isOn: true,
      isOverload: false,
    ),
    SocketInfo(
      id: 'xx_sock_02',
      name: '实验台B区',
      power: 280,
      isOn: true,
      isOverload: false,
    ),
    SocketInfo(
      id: 'xx_sock_03',
      name: '仪器设备区',
      power: 850,
      isOn: true,
      isOverload: false,
    ),
    SocketInfo(
      id: 'xx_sock_04',
      name: '通风设备',
      power: 200,
      isOn: true,
      isOverload: false,
    ),
  ];

  /// 获取总功率
  static double getTotalPower() {
    return getSocketData().fold<double>(
      0,
      (sum, socket) => sum + (socket.isOn ? socket.power : 0),
    );
  }

  /// 获取电压
  static double getVoltage() => 220.5;

  /// 获取漏电流
  static double getLeakageCurrent() {
    // 西学楼新实验室设备更新，漏电流更低
    return _currentLabId == 'lab_xixue_xinke' ? 2.8 : 5.2;
  }

  // ==================== 安防数据 ====================

  /// 获取门数据
  static List<DoorInfo> getDoorData() {
    switch (_currentLabId) {
      case 'lab_yuanlou_806':
        return _yuanlou806Doors;
      case 'lab_xixue_xinke':
        return _xixueXinkeDoors;
      default:
        return _yuanlou806Doors;
    }
  }

  /// 院楼806 门数据
  static const List<DoorInfo> _yuanlou806Doors = [
    DoorInfo(
      id: 'yl806_door_01',
      name: '实验室正门',
      isOpen: false,
      isLocked: true,
      hasCard: true,
    ),
  ];

  /// 西学楼新信科实验室 门数据
  static const List<DoorInfo> _xixueXinkeDoors = [
    DoorInfo(
      id: 'xx_door_01',
      name: '实验室正门',
      isOpen: false,
      isLocked: true,
      hasCard: true,
    ),
    DoorInfo(
      id: 'xx_door_02',
      name: '应急出口',
      isOpen: false,
      isLocked: true,
      hasCard: false,
    ),
  ];

  /// 获取窗户数据
  static List<WindowInfo> getWindowData() {
    switch (_currentLabId) {
      case 'lab_yuanlou_806':
        return _yuanlou806Windows;
      case 'lab_xixue_xinke':
        return _xixueXinkeWindows;
      default:
        return _yuanlou806Windows;
    }
  }

  /// 院楼806 窗户数据
  static const List<WindowInfo> _yuanlou806Windows = [
    WindowInfo(
      id: 'yl806_win_01',
      name: '南侧窗户',
      isOpen: true,
      openAngle: 30,
    ),
    WindowInfo(
      id: 'yl806_win_02',
      name: '北侧窗户',
      isOpen: false,
      openAngle: 0,
    ),
  ];

  /// 西学楼新信科实验室 窗户数据
  static const List<WindowInfo> _xixueXinkeWindows = [
    WindowInfo(
      id: 'xx_win_01',
      name: '东侧通风窗',
      isOpen: true,
      openAngle: 45,
    ),
    WindowInfo(
      id: 'xx_win_02',
      name: '西侧通风窗',
      isOpen: true,
      openAngle: 30,
    ),
  ];

  /// 是否有水浸传感器
  static bool hasWaterSensor() {
    return _currentLabId == 'lab_xixue_xinke';
  }

  /// 获取水浸状态
  static bool isWaterLeakDetected() => false;

  /// 获取水浸等级
  static double getWaterLeakLevel() => 0;

  // ==================== 环境数据 ====================

  /// 获取温度
  static double getTemperature() {
    // 模拟不同实验室略有差异的温度
    return _currentLabId == 'lab_xixue_xinke' ? 23.5 : 24.2;
  }

  /// 获取湿度
  static double getHumidity() {
    return _currentLabId == 'lab_xixue_xinke' ? 42.0 : 46.5;
  }

  /// 获取VOC指数
  static double getVocIndex() {
    // 新实验室VOC更低
    return _currentLabId == 'lab_xixue_xinke' ? 85.0 : 125.0;
  }

  /// 获取PM2.5
  static double getPm25() {
    return _currentLabId == 'lab_xixue_xinke' ? 18.0 : 28.0;
  }

  // ==================== 安全评分 ====================

  /// 计算安全评分
  static int calculateSafetyScore() {
    int score = 100;
    
    // 检查门窗状态
    final doors = getDoorData();
    final windows = getWindowData();
    
    for (final door in doors) {
      if (!door.isLocked) score -= 10;
    }
    
    for (final window in windows) {
      if (window.isOpen && window.openAngle > 60) score -= 3;
    }
    
    // 检查电源状态
    final leakage = getLeakageCurrent();
    if (leakage > 10) score -= 15;
    else if (leakage > 5) score -= 5;
    
    // 检查功率
    final power = getTotalPower();
    if (power > 3000) score -= 10;
    
    // 检查环境
    final voc = getVocIndex();
    if (voc > 300) score -= 15;
    else if (voc > 150) score -= 5;
    
    return score.clamp(0, 100);
  }
}
