import 'dart:async';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

import '../../features/alerts/domain/entities/alert.dart';

/// 通知服务
/// 
/// 负责本地通知和推送通知管理
/// 支持分级报警的不同通知策略
class NotificationService {
  final Logger _logger = Logger();
  
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  // 通知通道配置
  static const _criticalChannel = AndroidNotificationChannel(
    'critical_alerts',
    '紧急报警',
    description: '火灾、毒气泄漏、水浸等紧急报警',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
  
  static const _warningChannel = AndroidNotificationChannel(
    'warning_alerts',
    '预警通知',
    description: '温湿度超标、设备异常等预警',
    importance: Importance.high,
    playSound: true,
  );
  
  static const _infoChannel = AndroidNotificationChannel(
    'info_notifications',
    '信息通知',
    description: '设备上下线、巡检提醒等信息',
    importance: Importance.defaultImportance,
  );
  
  /// 初始化通知服务
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true, // iOS 紧急通知权限
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // 创建 Android 通知通道
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_criticalChannel);
      await androidPlugin.createNotificationChannel(_warningChannel);
      await androidPlugin.createNotificationChannel(_infoChannel);
    }
    
    _logger.i('通知服务初始化完成');
  }
  
  /// 处理通知点击
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    _logger.d('通知被点击: $payload');
    
    // TODO: 根据 payload 导航到相应页面
    // 例如: GoRouter.of(context).go('/alerts/$alertId');
  }
  
  /// 显示报警通知
  Future<void> showAlertNotification(Alert alert) async {
    final (channel, priority) = _getChannelAndPriority(alert.level);
    
    await _localNotifications.show(
      alert.id.hashCode,
      _getAlertTitle(alert),
      alert.message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: priority,
          ticker: alert.message,
          styleInformation: BigTextStyleInformation(
            alert.message,
            contentTitle: _getAlertTitle(alert),
            summaryText: _formatTimestamp(alert.timestamp),
          ),
          color: _getAlertColor(alert.level),
          // 紧急报警持续响铃直到用户处理
          ongoing: alert.level == AlertLevel.critical,
          autoCancel: alert.level != AlertLevel.critical,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: alert.level == AlertLevel.critical
              ? InterruptionLevel.critical
              : InterruptionLevel.timeSensitive,
        ),
      ),
      payload: alert.id,
    );
    
    _logger.i('已发送通知: ${alert.type}');
  }
  
  /// 取消通知
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
  
  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
  
  /// 根据报警级别获取通知通道和优先级
  (AndroidNotificationChannel, Priority) _getChannelAndPriority(AlertLevel level) {
    switch (level) {
      case AlertLevel.critical:
        return (_criticalChannel, Priority.max);
      case AlertLevel.warning:
        return (_warningChannel, Priority.high);
      case AlertLevel.info:
        return (_infoChannel, Priority.defaultPriority);
    }
  }
  
  /// 获取报警标题
  String _getAlertTitle(Alert alert) {
    final prefix = switch (alert.level) {
      AlertLevel.critical => '🚨 紧急报警',
      AlertLevel.warning => '⚠️ 预警',
      AlertLevel.info => 'ℹ️ 通知',
    };
    return '$prefix - ${alert.type.displayName}';
  }
  
  /// 获取报警颜色
  Color _getAlertColor(AlertLevel level) {
    return switch (level) {
      AlertLevel.critical => const Color(0xFFEF4444), // 红色
      AlertLevel.warning => const Color(0xFFF59E0B), // 黄色
      AlertLevel.info => const Color(0xFF3B82F6), // 蓝色
    };
  }
  
  /// 格式化时间戳
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} 小时前';
    } else {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
