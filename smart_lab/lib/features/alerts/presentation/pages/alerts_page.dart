import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/alert.dart';
import '../bloc/alerts_bloc.dart';

/// 告警中心页面
class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AlertsBloc>().add(LoadAlerts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('告警中心'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          BlocBuilder<AlertsBloc, AlertsState>(
            builder: (context, state) {
              if (state.unacknowledgedCount > 0) {
                return TextButton(
                  onPressed: () {
                    _showClearConfirmDialog(context);
                  },
                  child: const Text('全部确认'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<AlertsBloc, AlertsState>(
        builder: (context, state) {
          return Column(
            children: [
              // 统计卡片
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _AlertStats(
                  total: state.alerts.length,
                  critical: state.countByLevel[AlertLevel.critical] ?? 0,
                  warning: state.countByLevel[AlertLevel.warning] ?? 0,
                  info: state.countByLevel[AlertLevel.info] ?? 0,
                ),
              ),
              
              // 筛选标签
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: '全部',
                        count: state.alerts.length,
                        isSelected: state.selectedLevel == null,
                        onTap: () {
                          context.read<AlertsBloc>().add(const FilterAlerts(null));
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterChip(
                        label: '严重',
                        count: state.countByLevel[AlertLevel.critical] ?? 0,
                        color: AppColors.critical,
                        isSelected: state.selectedLevel == AlertLevel.critical,
                        onTap: () {
                          context.read<AlertsBloc>().add(
                            const FilterAlerts(AlertLevel.critical),
                          );
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterChip(
                        label: '预警',
                        count: state.countByLevel[AlertLevel.warning] ?? 0,
                        color: AppColors.warning,
                        isSelected: state.selectedLevel == AlertLevel.warning,
                        onTap: () {
                          context.read<AlertsBloc>().add(
                            const FilterAlerts(AlertLevel.warning),
                          );
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterChip(
                        label: '提示',
                        count: state.countByLevel[AlertLevel.info] ?? 0,
                        color: AppColors.info,
                        isSelected: state.selectedLevel == AlertLevel.info,
                        onTap: () {
                          context.read<AlertsBloc>().add(
                            const FilterAlerts(AlertLevel.info),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // 告警列表
              Expanded(
                child: state.filteredAlerts.isEmpty
                    ? _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        itemCount: state.filteredAlerts.length,
                        itemBuilder: (context, index) {
                          final alert = state.filteredAlerts[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: _AlertCard(
                              alert: alert,
                              onAcknowledge: () {
                                context.read<AlertsBloc>().add(
                                  AcknowledgeAlert(alert.id),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showClearConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认全部告警'),
        content: const Text('确定要将所有告警标记为已确认吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              context.read<AlertsBloc>().add(ClearAllAlerts());
              Navigator.pop(context);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}

/// 告警统计
class _AlertStats extends StatelessWidget {
  final int total;
  final int critical;
  final int warning;
  final int info;
  
  const _AlertStats({
    required this.total,
    required this.critical,
    required this.warning,
    required this.info,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
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
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              label: '总计',
              value: total.toString(),
              color: AppColors.primary,
            ),
          ),
          _Divider(),
          Expanded(
            child: _StatItem(
              label: '严重',
              value: critical.toString(),
              color: AppColors.critical,
            ),
          ),
          _Divider(),
          Expanded(
            child: _StatItem(
              label: '预警',
              value: warning.toString(),
              color: AppColors.warning,
            ),
          ),
          _Divider(),
          Expanded(
            child: _StatItem(
              label: '提示',
              value: info.toString(),
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'DINAlternate',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.divider,
    );
  }
}

/// 筛选 Chip
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _FilterChip({
    required this.label,
    required this.count,
    this.color,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.15) : Colors.white,
          borderRadius: AppSpacing.borderRadiusSm,
          border: Border.all(
            color: isSelected ? chipColor : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? chipColor : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isSelected ? chipColor : AppColors.inputBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 空状态
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.safe,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '暂无告警',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '实验室运行正常',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 告警卡片
class _AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback onAcknowledge;
  
  const _AlertCard({
    required this.alert,
    required this.onAcknowledge,
  });
  
  @override
  Widget build(BuildContext context) {
    final (bgColor, borderColor, iconColor) = switch (alert.level) {
      AlertLevel.critical => (
        AppColors.criticalLight,
        AppColors.critical.withOpacity(0.3),
        AppColors.critical,
      ),
      AlertLevel.warning => (
        AppColors.warningLight,
        AppColors.warning.withOpacity(0.3),
        AppColors.warning,
      ),
      AlertLevel.info => (
        AppColors.infoLight,
        AppColors.info.withOpacity(0.3),
        AppColors.info,
      ),
    };
    
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: alert.isAcknowledged ? Colors.white : bgColor,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: alert.isAcknowledged ? AppColors.border : borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: alert.isAcknowledged 
                      ? iconColor.withOpacity(0.1) 
                      : iconColor.withOpacity(0.2),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(
                  alert.type.icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: alert.isAcknowledged 
                                  ? TextDecoration.lineThrough 
                                  : null,
                              color: alert.isAcknowledged 
                                  ? AppColors.textSecondary 
                                  : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            alert.level.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.deviceName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Text(
            alert.message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(alert.timestamp),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              if (!alert.isAcknowledged)
                TextButton(
                  onPressed: onAcknowledge,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('确认'),
                )
              else
                Row(
                  children: [
                    Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.safe,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '已确认',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.safe,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
