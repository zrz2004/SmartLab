import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// 状态卡片组件
/// 
/// 用于仪表盘显示各类传感器状态概览
class StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subValue;
  final Color color;
  final StatusLevel status;
  final VoidCallback? onTap;
  
  const StatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.subValue,
    required this.color,
    this.status = StatusLevel.normal,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final borderColor = switch (status) {
      StatusLevel.normal => Colors.transparent,
      StatusLevel.warning => AppColors.warning,
      StatusLevel.critical => AppColors.critical,
    };
    
    final borderWidth = status == StatusLevel.normal ? 0.0 : 2.0;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: AppSpacing.cardPaddingCompact,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Icon(
                icon,
                size: AppSpacing.iconSm,
                color: color,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // 标题
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            
            // 数值
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: status == StatusLevel.critical 
                      ? AppColors.critical 
                      : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // 副标题
            if (subValue != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Flexible(
                child: Text(
                  subValue!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 状态级别枚举
enum StatusLevel {
  normal,
  warning,
  critical,
}
