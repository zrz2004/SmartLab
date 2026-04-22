import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/localization/dynamic_text_localizer.dart';
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
    final localizedTitle = alert.title.isEmpty
        ? alert.type.name
        : DynamicTextLocalizer.alertTitle(context, alert.title);
    final localizedMessage = DynamicTextLocalizer.alertMessage(context, alert.message);
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
                    localizedTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    localizedMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _relativeTime(context, alert.timestamp),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            if (!alert.isAcknowledged && onAcknowledge != null)
              TextButton(
                onPressed: onAcknowledge,
                child: Text(context.l10n.t('alert.acknowledge')),
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

  String _relativeTime(BuildContext context, DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return context.l10n.t('alert.justNow');
    if (diff.inHours < 1) {
      return context.l10n.t('alert.minutesAgo', params: {'minutes': '${diff.inMinutes}'});
    }
    if (diff.inDays < 1) {
      return context.l10n.t('alert.hoursAgo', params: {'hours': '${diff.inHours}'});
    }
    return context.l10n.t(
      'alert.dateShort',
      params: {'month': '${timestamp.month}', 'day': '${timestamp.day}'},
    );
  }
}
