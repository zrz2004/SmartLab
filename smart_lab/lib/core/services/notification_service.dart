import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logger/logger.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/alerts/domain/entities/alert.dart';
import '../../features/auth/domain/entities/user.dart';
import 'local_storage_service.dart';
import 'upload_reminder_models.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {}

class NotificationService {
  NotificationService({
    required LocalStorageService localStorageService,
  }) : _localStorageService = localStorageService;

  static const AndroidNotificationChannel _alertChannel =
      AndroidNotificationChannel(
    'smartlab_alerts',
    'SmartLab 安全预警',
    description: '实验室 AI 与设备安全预警通知',
    importance: Importance.max,
  );

  static const AndroidNotificationChannel _reminderChannel =
      AndroidNotificationChannel(
    'smartlab_upload_reminders',
    'SmartLab 上传提醒',
    description: '学生实验室安全图片上传提醒',
    importance: Importance.high,
  );

  final Logger _logger = Logger();
  final LocalStorageService _localStorageService;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<Map<String, dynamic>> _reminderTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  Map<String, dynamic>? _pendingReminderPayload;
  bool _initialized = false;

  Stream<Map<String, dynamic>> get uploadReminderTapStream =>
      _reminderTapController.stream;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (error) {
      _logger.w('Failed to resolve local timezone, fallback to Asia/Shanghai: $error');
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(_alertChannel);
    await androidImplementation?.createNotificationChannel(_reminderChannel);
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final payload = launchDetails?.notificationResponse?.payload;
    if (payload != null && payload.isNotEmpty) {
      _pendingReminderPayload = _tryParseReminderPayload(payload);
    }

    _initialized = true;
    _logger.i('Notification service initialized.');
  }

  Future<void> showAlertNotification(Alert alert) async {
    await _plugin.show(
      _stableId('alert_${alert.id}'),
      alert.title,
      alert.message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smartlab_alerts',
          'SmartLab 安全预警',
          channelDescription: '实验室 AI 与设备安全预警通知',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      payload: jsonEncode({
        'type': 'alert',
        'alertId': alert.id,
      }),
    );
    _logger.i('Notification queued for alert ${alert.id} (${alert.level.name}).');
  }

  Future<void> scheduleUploadReminderNotifications({
    required User? user,
    required List<LabReminderSettings> settings,
  }) async {
    await cancelUploadReminderNotifications();

    if (user == null || !_isReminderEligibleRole(user.role)) {
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    final scheduledIds = <int>[];

    for (final item in settings) {
      if (!item.enabled) {
        continue;
      }

      final lab = item.lab;
      for (final slot in item.slots) {
        final id = _stableId('upload_${lab.id}_${slot.key}');
        final scheduledAt = _nextInstance(now, slot.hour, slot.minute);
        final payload = jsonEncode({
          'type': 'upload_reminder',
          'labId': lab.id,
          'slotKey': slot.key,
        });

        await _plugin.zonedSchedule(
          id,
          '${lab.name} 图片上传提醒',
          '请在 ${slot.label} 后由学生上传实验室现场图片，供 AI 进行安全复核。',
          scheduledAt,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _reminderChannel.id,
              _reminderChannel.name,
              channelDescription: _reminderChannel.description,
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              styleInformation: BigTextStyleInformation(
                '${lab.name} 需要在 ${slot.label} 后完成一次安全图片上传。'
                '教师和管理员不显示此提醒。',
              ),
            ),
          ),
          payload: payload,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        scheduledIds.add(id);
      }
    }

    await _localStorageService.saveScheduledUploadReminderIds(scheduledIds);
  }

  Future<void> cancelUploadReminderNotifications() async {
    final ids = _localStorageService.getScheduledUploadReminderIds();
    for (final id in ids) {
      await _plugin.cancel(id);
    }
    await _localStorageService.saveScheduledUploadReminderIds(const <int>[]);
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
    _logger.i('Notification cancelled: $id');
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    await _localStorageService.saveScheduledUploadReminderIds(const <int>[]);
    _logger.i('All notifications cancelled.');
  }

  Map<String, dynamic>? takePendingUploadReminderPayload() {
    final payload = _pendingReminderPayload;
    _pendingReminderPayload = null;
    return payload;
  }

  void dispose() {
    _reminderTapController.close();
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }
    final parsed = _tryParseReminderPayload(payload);
    if (parsed != null) {
      _reminderTapController.add(parsed);
    }
  }

  Map<String, dynamic>? _tryParseReminderPayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic> &&
          decoded['type'] == 'upload_reminder') {
        return decoded;
      }
    } catch (_) {
      // ignore malformed payload
    }
    return null;
  }

  tz.TZDateTime _nextInstance(
    tz.TZDateTime now,
    int hour,
    int minute,
  ) {
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int _stableId(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }

  bool _isReminderEligibleRole(UserRole role) {
    return role == UserRole.graduate || role == UserRole.undergraduate;
  }
}
