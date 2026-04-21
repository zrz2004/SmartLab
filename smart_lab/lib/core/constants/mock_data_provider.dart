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

  static LabInfo get currentLab => LabConfig.getLabById(_currentLabId) ?? LabConfig.defaultLab;

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
    SocketInfo(id: 'yl806_sock_01', name: 'Server socket', power: 650, isOn: true, isOverload: false),
    SocketInfo(id: 'yl806_sock_02', name: 'Teacher socket', power: 180, isOn: true, isOverload: false),
    SocketInfo(id: 'yl806_sock_03', name: 'Student zone A', power: 420, isOn: true, isOverload: false),
    SocketInfo(id: 'yl806_sock_04', name: 'Student zone B', power: 380, isOn: true, isOverload: false),
  ];

  static const List<SocketInfo> _xixueSockets = [
    SocketInfo(id: 'xx_sock_01', name: 'Bench A socket', power: 320, isOn: true, isOverload: false),
    SocketInfo(id: 'xx_sock_02', name: 'Bench B socket', power: 280, isOn: true, isOverload: false),
    SocketInfo(id: 'xx_sock_03', name: 'Instrument socket', power: 850, isOn: true, isOverload: false),
    SocketInfo(id: 'xx_sock_04', name: 'Ventilation socket', power: 200, isOn: true, isOverload: false),
  ];

  static double getTotalPower() => getSocketData().fold<double>(0, (sum, socket) => sum + (socket.isOn ? socket.power : 0));
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
    DoorInfo(id: 'yl806_door_01', name: 'Main door', isOpen: false, isLocked: true, hasCard: true),
  ];

  static const List<DoorInfo> _xixueDoors = [
    DoorInfo(id: 'xx_door_01', name: 'Main door', isOpen: false, isLocked: true, hasCard: true),
    DoorInfo(id: 'xx_door_02', name: 'Emergency exit', isOpen: false, isLocked: true, hasCard: false),
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
    WindowInfo(id: 'yl806_win_01', name: 'South window', isOpen: true, openAngle: 30),
    WindowInfo(id: 'yl806_win_02', name: 'North window', isOpen: false, openAngle: 0),
  ];

  static const List<WindowInfo> _xixueWindows = [
    WindowInfo(id: 'xx_win_01', name: 'East window', isOpen: true, openAngle: 45),
    WindowInfo(id: 'xx_win_02', name: 'West window', isOpen: true, openAngle: 30),
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
