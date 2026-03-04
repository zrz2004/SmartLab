import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/status_card.dart';
import '../../../../shared/widgets/alert_item.dart';
import '../../../../shared/widgets/safety_score_card.dart';
import '../bloc/dashboard_bloc.dart';

/// 仪表盘页面
/// 
/// 首页综合展示:
/// - 安全评分卡片
/// - 快捷状态概览
/// - 实时告警流
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<DashboardBloc>().add(RefreshDashboard());
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 安全评分卡片
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: SafetyScoreCard(
                    score: state.safetyScore,
                    labName: state.currentLabName.isEmpty 
                        ? '院楼806' 
                        : state.currentLabName,
                    alertCount: state.unacknowledgedAlertCount,
                    onTap: () => context.push('/alerts'),
                  ),
                ),
              ),
              
              // 快捷状态概览标题
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '实时监测',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('查看全部'),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 状态卡片网格
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  delegate: SliverChildListDelegate([
                    // 环境监测
                    StatusCard(
                      icon: Icons.thermostat,
                      title: '环境监测',
                      value: '${state.latestTemperature?.toStringAsFixed(1) ?? '--'}°C',
                      subValue: '湿度 ${state.latestHumidity?.toStringAsFixed(0) ?? '--'}%',
                      color: AppColors.environment,
                      onTap: () => context.go('/environment'),
                    ),
                    
                    // 电源管理
                    StatusCard(
                      icon: Icons.flash_on,
                      title: '当前功率',
                      value: '${state.latestPower?.toStringAsFixed(0) ?? '--'} W',
                      subValue: '主回路: 通',
                      color: AppColors.power,
                      onTap: () => context.go('/power'),
                    ),
                    
                    // 水路安全
                    StatusCard(
                      icon: Icons.water_drop,
                      title: '水路安全',
                      value: '正常',
                      subValue: '流量: 0 L/min',
                      color: AppColors.water,
                      status: StatusLevel.normal,
                      onTap: () => context.go('/security'),
                    ),
                    
                    // 门窗状态
                    StatusCard(
                      icon: Icons.shield,
                      title: '门窗状态',
                      value: '全封闭',
                      subValue: '门禁: 已锁',
                      color: AppColors.security,
                      onTap: () => context.go('/security'),
                    ),
                  ]),
                ),
              ),
              
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl),
              ),
              
              // 实时告警流标题
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.notifications_active,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '实时告警',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      _ConnectionStatus(
                        isConnected: state.isMqttConnected,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.md),
              ),
              
              // 告警列表
              if (state.alerts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _EmptyAlerts(),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final alert = state.alerts[index];
                        return AlertItem(
                          alert: alert,
                          onTap: () {
                            // TODO: 导航到告警详情
                          },
                          onAcknowledge: () {
                            context.read<DashboardBloc>().add(
                              AcknowledgeAlert(alert.id),
                            );
                          },
                        );
                      },
                      childCount: state.alerts.length.clamp(0, 5),
                    ),
                  ),
                ),
              
              // 底部间距
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.bottomSafeArea),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// MQTT 连接状态指示器
class _ConnectionStatus extends StatelessWidget {
  final bool isConnected;
  
  const _ConnectionStatus({required this.isConnected});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isConnected ? AppColors.safeLight : AppColors.warningLight,
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isConnected ? AppColors.safe : AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'MQTT 已连接' : 'MQTT 离线',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isConnected ? AppColors.safe : AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 空告警状态
class _EmptyAlerts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.safeLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.safe.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: AppColors.safe,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '暂无异常报警',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.safe,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '实验室运行状态良好',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
