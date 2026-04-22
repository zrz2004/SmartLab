import '../constants/lab_config.dart';

class UploadReminderSlot {
  final String key;
  final int hour;
  final int minute;
  final String label;

  const UploadReminderSlot({
    required this.key,
    required this.hour,
    required this.minute,
    required this.label,
  });

  DateTime startAt(DateTime now) {
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'hour': hour,
      'minute': minute,
      'label': label,
    };
  }
}

class LabReminderSettings {
  final LabInfo lab;
  final bool enabled;
  final UploadReminderSlot firstSlot;
  final UploadReminderSlot secondSlot;
  final DateTime? updatedAt;
  final String? updatedBy;

  const LabReminderSettings({
    required this.lab,
    required this.enabled,
    required this.firstSlot,
    required this.secondSlot,
    this.updatedAt,
    this.updatedBy,
  });

  List<UploadReminderSlot> get slots => [firstSlot, secondSlot];

  Map<String, dynamic> toJson() {
    return {
      'labId': lab.id,
      'enabled': enabled,
      'firstReminderTime': firstSlot.label,
      'secondReminderTime': secondSlot.label,
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedBy': updatedBy,
      'slots': slots.map((slot) => slot.toJson()).toList(),
    };
  }
}

class PendingUploadReminderEntry {
  final LabInfo lab;
  final UploadReminderSlot slot;
  final DateTime scheduleTime;

  const PendingUploadReminderEntry({
    required this.lab,
    required this.slot,
    required this.scheduleTime,
  });
}

class PendingUploadReminder {
  final UploadReminderSlot slot;
  final DateTime scheduleTime;
  final List<PendingUploadReminderEntry> entries;

  const PendingUploadReminder({
    required this.slot,
    required this.scheduleTime,
    required this.entries,
  });

  List<LabInfo> get pendingLabs => entries.map((entry) => entry.lab).toList();

  String get title => '${slot.label} 图片上传提醒';

  String get description {
    final labNames = pendingLabs.map((lab) => lab.name).join('、');
    return '以下实验室在 ${slot.label} 后还未完成图片上传：$labNames。'
        '请学生尽快拍照或上传现场图片，完成 AI 安全复核。';
  }
}
