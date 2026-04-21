import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

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
        border: Border.all(color: isOn ? activeColor.withValues(alpha: 0.3) : AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isOn ? activeColor.withValues(alpha: 0.1) : AppColors.background,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(icon, size: 24, color: isOn ? activeColor : AppColors.textTertiary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
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
              activeThumbColor: activeColor,
              activeTrackColor: activeColor.withValues(alpha: 0.5),
              onChanged: onChanged == null ? null : (value) => _handleChange(context, value),
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

    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(value ? 'Confirm enable' : 'Confirm disable'),
        content: Text(confirmationMessage ?? 'Apply ${value ? 'enable' : 'disable'} to $title?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm')),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) onChanged?.call(value);
    });
  }
}
