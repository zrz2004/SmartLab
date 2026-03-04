/// 安全阈值配置
/// 
/// 基于工业安全标准 (OSHA, FDA) 定义
/// 所有阈值可通过后端配置覆盖
class SafetyThresholds {
  SafetyThresholds._();

  // ==================== 环境监测阈值 ====================
  
  /// 温度 (°C) - 依据 FDA 实验室标准
  static const double tempNormalMin = 20.0;
  static const double tempNormalMax = 25.0;
  static const double tempWarningMin = 18.0;
  static const double tempWarningMax = 27.0;
  static const double tempCriticalMin = 10.0;
  static const double tempCriticalMax = 35.0;
  
  /// 湿度 (% RH) - 防止静电或霉菌
  static const double humidityNormalMin = 30.0;
  static const double humidityNormalMax = 50.0;
  static const double humidityWarningMin = 25.0;
  static const double humidityWarningMax = 55.0;
  static const double humidityCriticalMin = 20.0;
  static const double humidityCriticalMax = 70.0;
  
  /// VOC 指数 - 依据 Sensirion/RESET 标准
  static const double vocNormalMax = 150.0;
  static const double vocWarningMax = 350.0;
  static const double vocCriticalMax = 400.0;
  
  /// PM2.5 (μg/m³)
  static const double pm25NormalMax = 35.0;
  static const double pm25WarningMax = 75.0;
  static const double pm25CriticalMax = 150.0;
  
  // ==================== 电气安全阈值 ====================
  
  /// 功率 (% 额定功率) - 防止过载起火
  static const double powerWarningPercent = 90.0;
  static const double powerCriticalPercent = 100.0;
  
  /// 漏电流 (mA) - 人身安全保护
  static const double leakageWarningMa = 15.0;
  static const double leakageCriticalMa = 30.0;
  
  /// 电压波动范围 (%)
  static const double voltageFluctuationWarning = 10.0;
  static const double voltageFluctuationCritical = 15.0;
  
  // ==================== 水路监测阈值 ====================
  
  /// 持续流量时间 (分钟) - 判定忘关水龙头
  static const int waterFlowWarningMinutes = 20;
  static const int waterFlowCriticalMinutes = 40;
  
  // ==================== 安防阈值 ====================
  
  /// 门窗开启时长 (分钟) - 空调开启时的节能预警
  static const int windowOpenWarningMinutes = 5;
  
  // ==================== 危化品管理阈值 ====================
  
  /// 试剂临期天数
  static const int chemicalExpiryWarningDays = 30;
  static const int chemicalExpiryCriticalDays = 0;
  
  /// RFID 盘点周期 (分钟)
  static const int rfidScanIntervalMinutes = 5;
  
  // ==================== 采样/响应频率 (毫秒) ====================
  
  /// 环境数据采样间隔
  static const int environmentSampleIntervalMs = 60000; // 1 分钟
  
  /// VOC 数据采样间隔
  static const int vocSampleIntervalMs = 10000; // 10 秒
  
  /// 电气数据采样间隔
  static const int powerSampleIntervalMs = 1000; // 1 秒
  
  /// 漏电流检测间隔 (实时)
  static const int leakageDetectionIntervalMs = 100;
  
  /// 水浸检测间隔 (实时)
  static const int waterLeakDetectionIntervalMs = 100;
  
  // ==================== 辅助方法 ====================
  
  /// 判断温度状态
  static SafetyLevel getTemperatureLevel(double temp) {
    if (temp >= tempNormalMin && temp <= tempNormalMax) {
      return SafetyLevel.normal;
    } else if (temp >= tempWarningMin && temp <= tempWarningMax) {
      return SafetyLevel.warning;
    } else {
      return SafetyLevel.critical;
    }
  }
  
  /// 判断湿度状态
  static SafetyLevel getHumidityLevel(double humidity) {
    if (humidity >= humidityNormalMin && humidity <= humidityNormalMax) {
      return SafetyLevel.normal;
    } else if (humidity >= humidityWarningMin && humidity <= humidityWarningMax) {
      return SafetyLevel.warning;
    } else {
      return SafetyLevel.critical;
    }
  }
  
  /// 判断 VOC 状态
  static SafetyLevel getVocLevel(double voc) {
    if (voc <= vocNormalMax) {
      return SafetyLevel.normal;
    } else if (voc <= vocWarningMax) {
      return SafetyLevel.warning;
    } else {
      return SafetyLevel.critical;
    }
  }
  
  /// 判断功率状态
  static SafetyLevel getPowerLevel(double currentPower, double ratedPower) {
    final percent = (currentPower / ratedPower) * 100;
    if (percent < powerWarningPercent) {
      return SafetyLevel.normal;
    } else if (percent < powerCriticalPercent) {
      return SafetyLevel.warning;
    } else {
      return SafetyLevel.critical;
    }
  }
  
  /// 判断漏电流状态
  static SafetyLevel getLeakageLevel(double leakageMa) {
    if (leakageMa < leakageWarningMa) {
      return SafetyLevel.normal;
    } else if (leakageMa < leakageCriticalMa) {
      return SafetyLevel.warning;
    } else {
      return SafetyLevel.critical;
    }
  }
}

/// 安全等级枚举
enum SafetyLevel {
  normal,
  warning,
  critical,
}
