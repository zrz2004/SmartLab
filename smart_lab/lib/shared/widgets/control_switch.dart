import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// 控制开关组件
/// 
/// 带有状态指示和确认对话框的开关按钮
class ControlSwitch extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isOn;
  final bool isLoading;
  final bool requireConfirmation;
  final String? confirmationMessage;
  final IconData icon;
  final Color activeColor;
  final ValueChanged<bool>? onChanged;
  
  const ControlSwitch({
    super.key,
    required this.title,
    this.subtitle,
    required this.isOn,
    this.isLoading = false,
    this.requireConfirmation = false,
    this.confirmationMessage,
    required this.icon,
    this.activeColor = AppColors.primary,
    this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isOn ? activeColor.withOpacity(0.3) : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isOn 
                  ? activeColor.withOpacity(0.1) 
                  : AppColors.background,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(
              icon,
              size: 24,
              color: isOn ? activeColor : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          
          // 文字信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // 开关
          if (isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(activeColor),
              ),
            )
          else
            Switch(
              value: isOn,
              onChanged: onChanged != null 
                  ? (value) => _handleChange(context, value)
                  : null,
              activeColor: activeColor,
            ),
        ],
      ),
    );
  }
  
  void _handleChange(BuildContext context, bool value) {
    if (!requireConfirmation) {
      onChanged?.call(value);
      return;
    }
    
    // 显示确认对话框
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(value ? '确认开启' : '确认关闭'),
        content: Text(
          confirmationMessage ?? '确定要${value ? '开启' : '关闭'}$title吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: value ? activeColor : AppColors.critical,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        onChanged?.call(value);
      }
    });
  }
}
