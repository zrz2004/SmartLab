import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// 本地存储服务
/// 
/// 负责本地数据持久化
/// - 普通数据: Hive
/// - 敏感数据: Flutter Secure Storage
class LocalStorageService {
  final Logger _logger = Logger();
  
  // Hive Box 名称
  static const String _settingsBox = 'settings';
  static const String _cacheBox = 'cache';
  static const String _alertsBox = 'offline_alerts';
  
  // 安全存储
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  /// 初始化存储
  Future<void> initialize() async {
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_cacheBox);
    await Hive.openBox(_alertsBox);
    _logger.i('本地存储初始化完成');
  }
  
  // ==================== 设置存储 ====================
  
  /// 保存设置
  Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }
  
  /// 获取设置
  T? getSetting<T>(String key, {T? defaultValue}) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue) as T?;
  }
  
  // ==================== 安全存储 (Token 等敏感数据) ====================
  
  /// 保存 Token
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }
  
  /// 获取 Access Token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }
  
  /// 获取 Refresh Token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }
  
  /// 清除 Token
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }
  
  // ==================== 缓存管理 ====================
  
  /// 保存缓存数据
  Future<void> cacheData(String key, dynamic data, {Duration? expiry}) async {
    final box = Hive.box(_cacheBox);
    final cacheEntry = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': expiry?.inMilliseconds,
    };
    await box.put(key, cacheEntry);
  }
  
  /// 获取缓存数据
  T? getCachedData<T>(String key) {
    final box = Hive.box(_cacheBox);
    final entry = box.get(key) as Map<dynamic, dynamic>?;
    
    if (entry == null) return null;
    
    // 检查过期
    final timestamp = entry['timestamp'] as int;
    final expiry = entry['expiry'] as int?;
    
    if (expiry != null) {
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(timestamp + expiry);
      if (DateTime.now().isAfter(expiryTime)) {
        box.delete(key); // 清除过期缓存
        return null;
      }
    }
    
    return entry['data'] as T?;
  }
  
  /// 清除所有缓存
  Future<void> clearCache() async {
    final box = Hive.box(_cacheBox);
    await box.clear();
  }
  
  // ==================== 离线报警存储 ====================
  
  /// 保存离线报警
  Future<void> saveOfflineAlert(Map<String, dynamic> alert) async {
    final box = Hive.box(_alertsBox);
    final alerts = box.get('alerts', defaultValue: <dynamic>[]) as List;
    alerts.add(alert);
    await box.put('alerts', alerts);
  }
  
  /// 获取离线报警
  List<Map<String, dynamic>> getOfflineAlerts() {
    final box = Hive.box(_alertsBox);
    final alerts = box.get('alerts', defaultValue: <dynamic>[]) as List;
    return alerts.cast<Map<String, dynamic>>();
  }
  
  /// 清除离线报警
  Future<void> clearOfflineAlerts() async {
    final box = Hive.box(_alertsBox);
    await box.delete('alerts');
  }
  
  // ==================== 用户偏好设置 ====================
  
  /// 获取主题模式
  String getThemeMode() {
    return getSetting<String>('theme_mode', defaultValue: 'system') ?? 'system';
  }
  
  /// 设置主题模式
  Future<void> setThemeMode(String mode) async {
    await saveSetting('theme_mode', mode);
  }
  
  /// 获取通知设置
  bool getNotificationEnabled() {
    return getSetting<bool>('notification_enabled', defaultValue: true) ?? true;
  }
  
  /// 设置通知开关
  Future<void> setNotificationEnabled(bool enabled) async {
    await saveSetting('notification_enabled', enabled);
  }
  
  /// 获取当前选中的实验室 ID
  String? getCurrentLabId() {
    return getSetting<String>('current_lab_id');
  }
  
  /// 设置当前选中的实验室 ID
  Future<void> setCurrentLabId(String labId) async {
    await saveSetting('current_lab_id', labId);
  }
}
