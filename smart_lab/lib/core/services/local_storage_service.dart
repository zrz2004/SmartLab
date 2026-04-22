import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

class LocalStorageService {
  final Logger _logger = Logger();

  static const String _settingsBox = 'settings';
  static const String _cacheBox = 'cache';
  static const String _alertsBox = 'offline_alerts';
  static const String _uploadsBox = 'pending_uploads';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<void> initialize() async {
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_cacheBox);
    await Hive.openBox(_alertsBox);
    await Hive.openBox(_uploadsBox);
    _logger.i('Local storage initialized');
  }

  Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: 'refresh_token');
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  Future<void> cacheData(String key, dynamic data, {Duration? expiry}) async {
    final box = Hive.box(_cacheBox);
    final cacheEntry = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': expiry?.inMilliseconds,
    };
    await box.put(key, cacheEntry);
  }

  T? getCachedData<T>(String key) {
    final box = Hive.box(_cacheBox);
    final entry = box.get(key) as Map<dynamic, dynamic>?;
    if (entry == null) return null;

    final timestamp = entry['timestamp'] as int;
    final expiry = entry['expiry'] as int?;
    if (expiry != null) {
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(timestamp + expiry);
      if (DateTime.now().isAfter(expiryTime)) {
        box.delete(key);
        return null;
      }
    }

    return entry['data'] as T?;
  }

  Future<void> clearCache() async {
    final box = Hive.box(_cacheBox);
    await box.clear();
  }

  Future<void> saveOfflineAlert(Map<String, dynamic> alert) async {
    final box = Hive.box(_alertsBox);
    final alerts = List<dynamic>.from(
      box.get('alerts', defaultValue: const <dynamic>[]),
    );
    alerts.add(alert);
    await box.put('alerts', alerts);
  }

  List<Map<String, dynamic>> getOfflineAlerts() {
    final box = Hive.box(_alertsBox);
    final alerts = List<dynamic>.from(
      box.get('alerts', defaultValue: const <dynamic>[]),
    );
    return alerts
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> clearOfflineAlerts() async {
    final box = Hive.box(_alertsBox);
    await box.delete('alerts');
  }

  String getThemeMode() {
    return getSetting<String>('theme_mode', defaultValue: 'system') ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    await saveSetting('theme_mode', mode);
  }

  String getLanguageCode() {
    return getSetting<String>('language_code', defaultValue: 'zh') ?? 'zh';
  }

  Future<void> setLanguageCode(String languageCode) async {
    await saveSetting('language_code', languageCode);
  }

  bool getNotificationEnabled() {
    return getSetting<bool>('notification_enabled', defaultValue: true) ?? true;
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    await saveSetting('notification_enabled', enabled);
  }

  String? getCurrentLabId() {
    return getSetting<String>('current_lab_id');
  }

  Future<void> setCurrentLabId(String labId) async {
    await saveSetting('current_lab_id', labId);
  }

  Future<void> clearCurrentLabId() async {
    final box = Hive.box(_settingsBox);
    await box.delete('current_lab_id');
  }

  Future<void> cacheLatestInspection(
    String cacheKey,
    Map<String, dynamic> inspection,
  ) async {
    await cacheData('latest_inspection_$cacheKey', inspection);
  }

  Map<String, dynamic>? getLatestInspection(String cacheKey) {
    return getCachedData<Map<String, dynamic>>('latest_inspection_$cacheKey');
  }

  Future<void> enqueuePendingUpload(Map<String, dynamic> payload) async {
    final box = Hive.box(_uploadsBox);
    final queue = List<dynamic>.from(
      box.get('items', defaultValue: const <dynamic>[]),
    );
    queue.add(payload);
    await box.put('items', queue);
  }

  List<Map<String, dynamic>> getPendingUploads() {
    final box = Hive.box(_uploadsBox);
    final queue = List<dynamic>.from(
      box.get('items', defaultValue: const <dynamic>[]),
    );
    return queue
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> replacePendingUploads(List<Map<String, dynamic>> items) async {
    final box = Hive.box(_uploadsBox);
    await box.put('items', items);
  }

  Future<void> saveLabUploadTimestamp(String labId, DateTime timestamp) async {
    await saveSetting('lab_upload_$labId', timestamp.toIso8601String());
  }

  DateTime? getLabUploadTimestamp(String labId) {
    final raw = getSetting<String>('lab_upload_$labId');
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool hasShownUploadReminder({
    required String userId,
    required String labId,
    required String slotKey,
    required DateTime date,
  }) {
    final dayKey = _formatDayKey(date);
    return getSetting<bool>(
          'upload_reminder_shown_${userId}_${labId}_${slotKey}_$dayKey',
          defaultValue: false,
        ) ??
        false;
  }

  Future<void> markUploadReminderShown({
    required String userId,
    required String labId,
    required String slotKey,
    required DateTime date,
  }) async {
    final dayKey = _formatDayKey(date);
    await saveSetting(
      'upload_reminder_shown_${userId}_${labId}_${slotKey}_$dayKey',
      true,
    );
  }

  Future<void> saveLabReminderSettings(
    String labId,
    Map<String, dynamic> settings,
  ) async {
    await saveSetting('lab_reminder_settings_$labId', settings);
  }

  Map<String, dynamic>? getLabReminderSettings(String labId) {
    final raw = getSetting<dynamic>('lab_reminder_settings_$labId');
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return null;
  }

  Future<void> saveScheduledUploadReminderIds(List<int> ids) async {
    await saveSetting('scheduled_upload_reminder_ids', ids);
  }

  List<int> getScheduledUploadReminderIds() {
    final raw = getSetting<dynamic>(
      'scheduled_upload_reminder_ids',
      defaultValue: const <dynamic>[],
    );
    if (raw is List) {
      return raw
          .map((item) => int.tryParse(item.toString()))
          .whereType<int>()
          .toList();
    }
    return const <int>[];
  }

  String _formatDayKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
