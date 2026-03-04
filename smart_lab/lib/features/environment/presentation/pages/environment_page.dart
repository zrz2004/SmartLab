import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/safety_thresholds.dart';
import '../../../../shared/widgets/realtime_chart.dart';
import '../../../../shared/widgets/sensor_gauge.dart';
import '../bloc/environment_bloc.dart';

/// 环境监测页面
class EnvironmentPage extends StatefulWidget {
  const EnvironmentPage({super.key});

  @override
  State<EnvironmentPage> createState() => _EnvironmentPageState();
}

class _EnvironmentPageState extends State<EnvironmentPage> {
  @override
  void initState() {
    super.initState();
    context.read<EnvironmentBloc>().add(LoadEnvironmentData());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EnvironmentBloc, EnvironmentState>(
      builder: (context, state) {
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 页面标题
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '环境监测中心',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '实时监控温湿度、空气质量',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    _StatusIndicator(
                      status: state.status == EnvironmentStatus.loaded 
                          ? '实时更新中' 
                          : '加载中...',
                      isOnline: state.status == EnvironmentStatus.loaded,
                    ),
                  ],
                ),
              ),
            ),
            
            // 传感器仪表盘
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
                  // 温度
                  SensorGauge(
                    label: '温度',
                    value: state.currentTemperature ?? 22.5,
                    unit: '°C',
                    minValue: 0,
                    maxValue: 50,
                    warningValue: SafetyThresholds.tempWarningMax,
                    criticalValue: SafetyThresholds.tempCriticalMax,
                    primaryColor: AppColors.environment,
                    icon: Icons.thermostat,
                  ),
                  
                  // 湿度
                  SensorGauge(
                    label: '湿度',
                    value: state.currentHumidity ?? 45,
                    unit: '%',
                    minValue: 0,
                    maxValue: 100,
                    warningValue: SafetyThresholds.humidityWarningMax,
                    criticalValue: SafetyThresholds.humidityCriticalMax,
                    primaryColor: AppColors.water,
                    icon: Icons.water_drop,
                  ),
                ]),
              ),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.lg),
            ),
            
            // 温度曲线图
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: RealtimeChart(
                  data: state.temperatureHistory.isNotEmpty 
                      ? state.temperatureHistory 
                      : _generateMockData(),
                  title: '温度趋势',
                  unit: '°C',
                  lineColor: AppColors.environment,
                  warningThreshold: SafetyThresholds.tempWarningMax,
                  criticalThreshold: SafetyThresholds.tempCriticalMax,
                ),
              ),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.lg),
            ),
            
            // VOC 指数卡片
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _VocCard(
                  value: state.currentVoc ?? 120,
                  level: state.vocLevel,
                ),
              ),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.lg),
            ),
            
            // 阈值设置按钮
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showThresholdSettings(context);
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('阈值配置'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            
            // 底部间距
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.bottomSafeArea),
            ),
          ],
        );
      },
    );
  }
  
  List<FlSpot> _generateMockData() {
    return List.generate(30, (i) => FlSpot(i.toDouble(), 22 + (i % 5) * 0.5));
  }
  
  void _showThresholdSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拖动指示器
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              Text(
                '阈值配置',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              
              Text(
                '设置环境参数的预警和报警阈值',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // TODO: 添加阈值设置表单
              const Text('阈值设置功能开发中...'),
            ],
          ),
        ),
      ),
    );
  }
}

/// 状态指示器
class _StatusIndicator extends StatelessWidget {
  final String status;
  final bool isOnline;
  
  const _StatusIndicator({
    required this.status,
    required this.isOnline,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isOnline ? AppColors.safeLight : AppColors.warningLight,
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.safe : AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isOnline ? AppColors.safe : AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// VOC 指数卡片
class _VocCard extends StatelessWidget {
  final double value;
  final SafetyLevel level;
  
  const _VocCard({
    required this.value,
    required this.level,
  });
  
  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor, label) = switch (level) {
      SafetyLevel.normal => (AppColors.safeLight, AppColors.safe, '空气质量优良'),
      SafetyLevel.warning => (AppColors.warningLight, AppColors.warning, '空气质量一般'),
      SafetyLevel.critical => (AppColors.criticalLight, AppColors.critical, '空气质量较差'),
    };
    
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '空气质量 (VOC Index)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
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
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // 数值和进度条
          Row(
            children: [
              Text(
                value.toStringAsFixed(0),
                style: const TextStyle(
                  fontFamily: 'DINAlternate',
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ppb',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / 500).clamp(0, 1),
              minHeight: 8,
              backgroundColor: AppColors.progressTrack,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // 图例
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendItem(label: '优良', color: AppColors.safe),
              _LegendItem(label: '一般', color: AppColors.warning),
              _LegendItem(label: '较差', color: AppColors.critical),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  
  const _LegendItem({
    required this.label,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
