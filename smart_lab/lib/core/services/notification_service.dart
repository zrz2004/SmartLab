import 'package:logger/logger.dart';

import '../../features/alerts/domain/entities/alert.dart';

class NotificationService {
  final Logger _logger = Logger();

  Future<void> initialize() async {
    _logger.i('Notification service initialized.');
  }

  Future<void> showAlertNotification(Alert alert) async {
    _logger.i('Notification queued for alert ${alert.id} (${alert.level.name}).');
  }

  Future<void> cancelNotification(int id) async {
    _logger.i('Notification cancelled: $id');
  }

  Future<void> cancelAllNotifications() async {
    _logger.i('All notifications cancelled.');
  }
}
