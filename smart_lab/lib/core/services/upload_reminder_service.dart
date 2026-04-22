import '../../features/auth/domain/entities/user.dart';
import '../constants/lab_config.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';
import 'upload_reminder_models.dart';

class UploadReminderService {
  UploadReminderService({
    required LocalStorageService localStorageService,
    required ApiService apiService,
    required NotificationService notificationService,
  })  : _localStorageService = localStorageService,
        _apiService = apiService,
        _notificationService = notificationService;

  final LocalStorageService _localStorageService;
  final ApiService _apiService;
  final NotificationService _notificationService;

  static bool isReminderEligibleRole(UserRole role) {
    return role == UserRole.graduate || role == UserRole.undergraduate;
  }

  bool isReminderEligible(User? user) {
    if (user == null) return false;
    return isReminderEligibleRole(user.role);
  }

  static UploadReminderSlot slotFromTime({
    required String key,
    required String time,
  }) {
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 19 : 19;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return UploadReminderSlot(
      key: key,
      hour: hour,
      minute: minute,
      label:
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    );
  }

  static LabReminderSettings defaultSettingsForLab(LabInfo lab) {
    return LabReminderSettings(
      lab: lab,
      enabled: true,
      firstSlot: slotFromTime(
        key: 'slot_1',
        time: '19:00',
      ),
      secondSlot: slotFromTime(
        key: 'slot_2',
        time: '23:00',
      ),
    );
  }

  static LabReminderSettings settingsFromJson(
    LabInfo lab,
    Map<String, dynamic> json,
  ) {
    final firstTime =
        (json['firstReminderTime'] ?? json['first_reminder_time'] ?? '19:00')
            .toString();
    final secondTime =
        (json['secondReminderTime'] ?? json['second_reminder_time'] ?? '23:00')
            .toString();
    return LabReminderSettings(
      lab: lab,
      enabled: json['enabled'] as bool? ?? true,
      firstSlot: slotFromTime(key: 'slot_1', time: firstTime),
      secondSlot: slotFromTime(key: 'slot_2', time: secondTime),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : null,
      updatedBy: (json['updatedBy'] ?? json['updated_by'])?.toString(),
    );
  }

  Future<void> recordSuccessfulUpload(String labId, {DateTime? uploadedAt}) async {
    await _localStorageService.saveLabUploadTimestamp(
      labId,
      uploadedAt ?? DateTime.now(),
    );
  }

  Future<Map<String, LabReminderSettings>> syncReminderConfiguration({
    required User? user,
    required List<LabInfo> labs,
    bool forceRefresh = false,
  }) async {
    if (user == null || labs.isEmpty) {
      await _notificationService.cancelUploadReminderNotifications();
      return const {};
    }

    final settings = <String, LabReminderSettings>{};
    for (final lab in labs) {
      settings[lab.id] = await getReminderSettings(
        lab,
        forceRefresh: forceRefresh,
      );
    }

    await _notificationService.scheduleUploadReminderNotifications(
      user: user,
      settings: settings.values.toList(),
    );
    return settings;
  }

  Future<LabReminderSettings> getReminderSettings(
    LabInfo lab, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _localStorageService.getLabReminderSettings(lab.id);
      if (cached != null) {
        return settingsFromJson(lab, cached);
      }
    }

    try {
      final response = await _apiService.getLabReminderSettings(lab.id);
      final settings = settingsFromJson(lab, response);
      await _localStorageService.saveLabReminderSettings(lab.id, settings.toJson());
      return settings;
    } catch (_) {
      final cached = _localStorageService.getLabReminderSettings(lab.id);
      if (cached != null) {
        return settingsFromJson(lab, cached);
      }
      return defaultSettingsForLab(lab);
    }
  }

  Future<LabReminderSettings> updateReminderSettings({
    required LabInfo lab,
    required bool enabled,
    required String firstReminderTime,
    required String secondReminderTime,
  }) async {
    final response = await _apiService.updateLabReminderSettings(
      labId: lab.id,
      enabled: enabled,
      firstReminderTime: firstReminderTime,
      secondReminderTime: secondReminderTime,
    );
    final settings = settingsFromJson(lab, response);
    await _localStorageService.saveLabReminderSettings(lab.id, settings.toJson());
    return settings;
  }

  Future<PendingUploadReminder?> getDueReminder({
    required User? user,
    required List<LabInfo> labs,
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    if (!isReminderEligible(user) ||
        labs.isEmpty ||
        !_localStorageService.getNotificationEnabled()) {
      return null;
    }

    final groupedEntries = <String, List<PendingUploadReminderEntry>>{};

    for (final lab in labs) {
      final settings = await getReminderSettings(lab);
      if (!settings.enabled) {
        continue;
      }

      for (final slot in settings.slots) {
        final slotStart = slot.startAt(currentTime);
        if (currentTime.isBefore(slotStart)) {
          continue;
        }

        if (_localStorageService.hasShownUploadReminder(
          userId: user!.id,
          labId: lab.id,
          slotKey: slot.key,
          date: currentTime,
        )) {
          continue;
        }

        final uploadAt = _localStorageService.getLabUploadTimestamp(lab.id);
        if (uploadAt != null && !uploadAt.isBefore(slotStart)) {
          continue;
        }

        final groupKey = '${slot.label}_${slot.key}';
        groupedEntries.putIfAbsent(groupKey, () => <PendingUploadReminderEntry>[]);
        groupedEntries[groupKey]!.add(
          PendingUploadReminderEntry(
            lab: lab,
            slot: slot,
            scheduleTime: slotStart,
          ),
        );
      }
    }

    if (groupedEntries.isEmpty) {
      return null;
    }

    final orderedEntries = groupedEntries.values.toList()
      ..sort((left, right) =>
          right.first.scheduleTime.compareTo(left.first.scheduleTime));
    final selectedEntries = orderedEntries.first;
    return PendingUploadReminder(
      slot: selectedEntries.first.slot,
      scheduleTime: selectedEntries.first.scheduleTime,
      entries: selectedEntries,
    );
  }

  Future<void> markReminderShown({
    required String userId,
    required PendingUploadReminder reminder,
  }) async {
    for (final entry in reminder.entries) {
      await _localStorageService.markUploadReminderShown(
        userId: userId,
        labId: entry.lab.id,
        slotKey: entry.slot.key,
        date: entry.scheduleTime,
      );
    }
  }
}
