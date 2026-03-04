import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/alerts/domain/entities/alert.dart';

/// 报警项组件
/// 
/// 显示单条报警信息，支持不同级别的视觉区分
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
    final (bgColor, borderColor, iconColor) = _getColors(alert.level);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图标
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(
                _getIcon(alert.type),
                size: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和级别标签
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.type.displayName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _LevelBadge(level: alert.level),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  
                  // 消息内容
                  Text(
                    alert.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  // 时间和操作
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(alert.timestamp),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      if (!alert.isAcknowledged && onAcknowledge != null)
                        GestureDetector(
                          onTap: onAcknowledge,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppSpacing.borderRadiusSm,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '确认',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  (Color, Color, Color) _getColors(AlertLevel level) {
    switch (level) {
      case AlertLevel.critical:
        return (
          AppColors.criticalLight,
          AppColors.critical.withOpacity(0.3),
          AppColors.critical,
        );
      case AlertLevel.warning:
        return (
          AppColors.warningLight,
          AppColors.warning.withOpacity(0.3),
          AppColors.warning,
        );
      case AlertLevel.info:
        return (
          AppColors.infoLight,
          AppColors.info.withOpacity(0.3),
          AppColors.info,
        );
    }
  }
  
  IconData _getIcon(AlertType type) {
    switch (type) {
      case AlertType.temperatureHigh:
      case AlertType.temperatureLow:
        return Icons.thermostat;
      case AlertType.humidityHigh:
      case AlertType.humidityLow:
        return Icons.water_drop;
      case AlertType.vocHigh:
      case AlertType.gasLeak:
        return Icons.air;
      case AlertType.powerOverload:
      case AlertType.leakageCurrent:
      case AlertType.arcFault:
      case AlertType.voltageAbnormal:
        return Icons.flash_on;
      case AlertType.waterLeak:
      case AlertType.tapForgotten:
        return Icons.water;
      case AlertType.doorUnlocked:
      case AlertType.windowOpen:
      case AlertType.intrusion:
        return Icons.shield;
      case AlertType.chemicalMissing:
      case AlertType.chemicalExpired:
      case AlertType.chemicalIncompatible:
      case AlertType.unauthorizedAccess:
        return Icons.science;
      case AlertType.deviceOffline:
      case AlertType.deviceError:
      case AlertType.batteryLow:
        return Icons.sensors_off;
      default:
        return Icons.warning;
    }
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小时前';
    } else {
      return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// 级别标签组件
class _LevelBadge extends StatelessWidget {
  final AlertLevel level;
  
  const _LevelBadge({required this.level});
  
  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = switch (level) {
      AlertLevel.critical => (AppColors.critical, Colors.white),
      AlertLevel.warning => (AppColors.warning, Colors.white),
      AlertLevel.info => (AppColors.info, Colors.white),
    };
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        level.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
