import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// 传感器数值指示器组件
/// 
/// 圆形仪表盘样式，用于显示单个传感器数值
class SensorGauge extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double minValue;
  final double maxValue;
  final double? warningValue;
  final double? criticalValue;
  final Color primaryColor;
  final IconData? icon;
  
  const SensorGauge({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.minValue = 0,
    this.maxValue = 100,
    this.warningValue,
    this.criticalValue,
    this.primaryColor = AppColors.primary,
    this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    final percentage = ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
    final color = _getStatusColor();
    
    return Container(
      padding: AppSpacing.cardPaddingCompact,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // 仪表盘
          Flexible(
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 背景圆环
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 6,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.progressTrack,
                      ),
                    ),
                  ),
                  
                  // 进度圆环
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: percentage),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedValue, child) {
                        return CircularProgressIndicator(
                          value: animatedValue,
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        );
                      },
                    ),
                  ),
                  
                  // 中心数值
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: color,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        unit,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.xs),
          
          // 状态标签
          _StatusLabel(color: color),
        ],
      ),
    );
  }
  
  Color _getStatusColor() {
    if (criticalValue != null && value >= criticalValue!) {
      return AppColors.critical;
    }
    if (warningValue != null && value >= warningValue!) {
      return AppColors.warning;
    }
    return primaryColor;
  }
}

class _StatusLabel extends StatelessWidget {
  final Color color;
  
  const _StatusLabel({required this.color});
  
  @override
  Widget build(BuildContext context) {
    final (label, bgColor) = _getStatusInfo();
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
  
  (String, Color) _getStatusInfo() {
    if (color == AppColors.critical) {
      return ('异常', AppColors.criticalLight);
    } else if (color == AppColors.warning) {
      return ('预警', AppColors.warningLight);
    } else {
      return ('正常', AppColors.safeLight);
    }
  }
}
