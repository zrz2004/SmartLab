import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/alerts/domain/entities/alert.dart';

class AlertItem extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onTap;
  final VoidCallback? onAcknowledge;

  const AlertItem({
    super.key,
    required this.alert,
    this.onTap,
    this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(alert.level);

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: levelColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: levelColor.withValues(alpha: 0.12),
              child: Icon(alert.type.icon, color: levelColor, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title.isEmpty ? alert.type.name : alert.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    alert.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _relativeTime(alert.timestamp),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            if (!alert.isAcknowledged && onAcknowledge != null)
              TextButton(
                onPressed: onAcknowledge,
                child: const Text('Acknowledge'),
              ),
          ],
        ),
      ),
    );
  }

  Color _levelColor(AlertLevel level) {
    switch (level) {
      case AlertLevel.critical:
        return AppColors.critical;
      case AlertLevel.warning:
        return AppColors.warning;
      case AlertLevel.info:
        return AppColors.info;
    }
  }

  String _relativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} h ago';
    return '${timestamp.month}/${timestamp.day}';
  }
}
