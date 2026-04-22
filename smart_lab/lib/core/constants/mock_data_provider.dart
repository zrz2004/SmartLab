import 'lab_config.dart';
import '../../features/power/presentation/bloc/power_bloc.dart';
import '../../features/security/presentation/bloc/security_bloc.dart';

class MockDataProvider {
  MockDataProvider._();

  static String _currentLabId = LabConfig.defaultLab.id;

  static String get currentLabId => _currentLabId;

  static void setCurrentLab(String labId) {
    _currentLabId = labId;
  }

  static LabInfo get currentLab =>
      LabConfig.getLabById(_currentLabId) ?? LabConfig.defaultLab;

  static List<SocketInfo> getSocketData() {
    switch (_currentLabId) {
      case 'lab_xixue_xinke':
        return _xixueSockets;
      case 'lab_yuanlou_806':
      default:
        return _yuanlouSockets;
    }
  }

  static const List<SocketInfo> _yuanlouSockets = [
    SocketInfo(id: 'yl806_sock_01', name: '服务器插座', power: 650, isOn: true, isOverload: false),
    SocketInfo(id: 'yl806_sock_02', name: '教师工位插座', power: 180, isOn: true, isOverload: false),
    SocketInfo(id: 'yl806_sock_03', name: '学生区A插座', power: 420, isOn: true, isOverload: false),
    SocketInfo(id: 'yl806_sock_04', name: '学生区B插座', power: 380, isOn: true, isOverload: false),
  ];

  static const List<SocketInfo> _xixueSockets = [
    SocketInfo(id: 'xx_sock_01', name: '实验台A插座', power: 320, isOn: true, isOverload: false),
    SocketInfo(id: 'xx_sock_02', name: '实验台B插座', power: 280, isOn: true, isOverload: false),
    SocketInfo(id: 'xx_sock_03', name: '仪器区插座', power: 850, isOn: true, isOverload: false),
    SocketInfo(id: 'xx_sock_04', name: '通风设备插座', power: 200, isOn: true, isOverload: false),
  ];

  static double getTotalPower() => getSocketData().fold<double>(
        0,
        (sum, socket) => sum + (socket.isOn ? socket.power : 0),
      );
  static double getVoltage() => 220.5;
  static double getLeakageCurrent() => _currentLabId == 'lab_xixue_xinke' ? 2.8 : 5.2;

  static List<DoorInfo> getDoorData() {
    switch (_currentLabId) {
      case 'lab_xixue_xinke':
        return _xixueDoors;
      case 'lab_yuanlou_806':
      default:
        return _yuanlouDoors;
    }
  }

  static const List<DoorInfo> _yuanlouDoors = [
    DoorInfo(id: 'yl806_door_01', name: '主门', isOpen: false, isLocked: true, hasCard: true),
  ];

  static const List<DoorInfo> _xixueDoors = [
    DoorInfo(id: 'xx_door_01', name: '主门', isOpen: false, isLocked: true, hasCard: true),
    DoorInfo(id: 'xx_door_02', name: '应急门', isOpen: false, isLocked: true, hasCard: false),
  ];

  static List<WindowInfo> getWindowData() {
    switch (_currentLabId) {
      case 'lab_xixue_xinke':
        return _xixueWindows;
      case 'lab_yuanlou_806':
      default:
        return _yuanlouWindows;
    }
  }

  static const List<WindowInfo> _yuanlouWindows = [
    WindowInfo(id: 'yl806_win_01', name: '南侧窗户', isOpen: true, openAngle: 30),
    WindowInfo(id: 'yl806_win_02', name: '北侧窗户', isOpen: false, openAngle: 0),
  ];

  static const List<WindowInfo> _xixueWindows = [
    WindowInfo(id: 'xx_win_01', name: '东侧窗户', isOpen: true, openAngle: 45),
    WindowInfo(id: 'xx_win_02', name: '西侧窗户', isOpen: true, openAngle: 30),
  ];

  static bool hasWaterSensor() => _currentLabId == 'lab_xixue_xinke';
  static bool isWaterLeakDetected() => false;
  static double getWaterLeakLevel() => 0;

  static double getTemperature() => _currentLabId == 'lab_xixue_xinke' ? 23.5 : 24.2;
  static double getHumidity() => _currentLabId == 'lab_xixue_xinke' ? 42.0 : 46.5;
  static double getVocIndex() => _currentLabId == 'lab_xixue_xinke' ? 85.0 : 125.0;
  static double getPm25() => _currentLabId == 'lab_xixue_xinke' ? 18.0 : 28.0;

  static int calculateSafetyScore() {
    var score = 100;
    for (final door in getDoorData()) {
      if (!door.isLocked) score -= 10;
    }
    for (final window in getWindowData()) {
      if (window.isOpen && window.openAngle > 60) score -= 3;
    }
    final leakage = getLeakageCurrent();
    if (leakage > 10) score -= 15;
    if (getTotalPower() > 3000) score -= 10;
    final voc = getVocIndex();
    if (voc > 300) score -= 15;
    return score.clamp(0, 100);
  }
}
