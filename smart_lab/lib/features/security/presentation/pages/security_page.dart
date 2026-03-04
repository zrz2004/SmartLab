import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/control_switch.dart';
import '../bloc/security_bloc.dart';

/// 安防管理页面 (水路 + 门窗)
class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<SecurityBloc>().add(LoadSecurityData());
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SecurityBloc, SecurityState>(
      builder: (context, state) {
        return Column(
          children: [
            // Tab 切换
            Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.borderRadiusMd,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 4,
                    ),
                  ],
                ),
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '水路管理'),
                  Tab(text: '门窗安防'),
                ],
              ),
            ),
            
            // Tab 内容
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _WaterManagement(state: state),
                  _DoorWindowManagement(state: state),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 水路管理 Tab
class _WaterManagement extends StatelessWidget {
  final SecurityState state;
  
  const _WaterManagement({required this.state});
  
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        // 漏水警报卡片
        if (state.waterLeakDetected)
          _WaterLeakAlertCard(leakLevel: state.waterLeakLevel),
        
        // 主阀门控制
        _ValveControlCard(
          isOpen: state.mainValveOpen,
          isControlling: state.isControlling,
          onToggle: () {
            context.read<SecurityBloc>().add(
              ToggleWaterValve(!state.mainValveOpen),
            );
          },
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // 漏水监测点
        Text(
          '漏水监测点',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        
        _WaterSensorItem(
          name: '水槽区域',
          isAlert: false,
          lastCheck: DateTime.now(),
        ),
        const SizedBox(height: AppSpacing.sm),
        _WaterSensorItem(
          name: '空调冷凝管',
          isAlert: false,
          lastCheck: DateTime.now(),
        ),
        const SizedBox(height: AppSpacing.sm),
        _WaterSensorItem(
          name: '消防管道接口',
          isAlert: false,
          lastCheck: DateTime.now(),
        ),
        
        const SizedBox(height: AppSpacing.bottomSafeArea),
      ],
    );
  }
}

/// 漏水警报卡片
class _WaterLeakAlertCard extends StatelessWidget {
  final double leakLevel;
  
  const _WaterLeakAlertCard({required this.leakLevel});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.criticalLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.critical.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.critical.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.water_damage,
              color: AppColors.critical,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ 检测到漏水',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.critical,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '水位: ${leakLevel.toStringAsFixed(1)} mm',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {
              context.read<SecurityBloc>().add(const ToggleWaterValve(false));
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.critical,
            ),
            child: const Text('紧急关阀'),
          ),
        ],
      ),
    );
  }
}

/// 阀门控制卡片
class _ValveControlCard extends StatelessWidget {
  final bool isOpen;
  final bool isControlling;
  final VoidCallback onToggle;
  
  const _ValveControlCard({
    required this.isOpen,
    required this.isControlling,
    required this.onToggle,
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isOpen ? AppColors.waterLight : AppColors.criticalLight,
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Icon(
                  isOpen ? Icons.water_drop : Icons.water_drop_outlined,
                  color: isOpen ? AppColors.water : AppColors.critical,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '主进水阀',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      isOpen ? '阀门已开启' : '阀门已关闭',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOpen ? AppColors.safe : AppColors.critical,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isOpen,
                onChanged: isControlling ? null : (_) => onToggle(),
                activeColor: AppColors.water,
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // 阀门状态图示
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ValveInfoItem(
                  label: '控制方式',
                  value: 'Modbus',
                  icon: Icons.settings_remote,
                ),
                _ValveInfoItem(
                  label: '响应时间',
                  value: '< 1s',
                  icon: Icons.timer,
                ),
                _ValveInfoItem(
                  label: '上次操作',
                  value: '2分钟前',
                  icon: Icons.history,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValveInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  
  const _ValveInfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
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

/// 漏水传感器项
class _WaterSensorItem extends StatelessWidget {
  final String name;
  final bool isAlert;
  final DateTime lastCheck;
  
  const _WaterSensorItem({
    required this.name,
    required this.isAlert,
    required this.lastCheck,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isAlert ? Icons.warning : Icons.check_circle,
            color: isAlert ? AppColors.critical : AppColors.safe,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '最后检测: ${_formatTime(lastCheck)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isAlert ? AppColors.criticalLight : AppColors.safeLight,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Text(
              isAlert ? '警报' : '正常',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isAlert ? AppColors.critical : AppColors.safe,
              ),
            ),
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
    return '${diff.inDays}天前';
  }
}

/// 门窗管理 Tab
class _DoorWindowManagement extends StatelessWidget {
  final SecurityState state;
  
  const _DoorWindowManagement({required this.state});
  
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        // 门状态
        Text(
          '门禁状态',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        
        ...state.doors.map((door) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _DoorItem(
            door: door,
            onToggleLock: (lock) {
              context.read<SecurityBloc>().add(ToggleDoor(door.id, lock));
            },
          ),
        )),
        
        const SizedBox(height: AppSpacing.lg),
        
        // 窗户状态
        Text(
          '窗户状态',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        
        ...state.windows.map((window) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _WindowItem(
            window: window,
            onToggle: (open) {
              context.read<SecurityBloc>().add(ToggleWindow(window.id, open));
            },
          ),
        )),
        
        const SizedBox(height: AppSpacing.bottomSafeArea),
      ],
    );
  }
}

/// 门项
class _DoorItem extends StatelessWidget {
  final DoorInfo door;
  final ValueChanged<bool> onToggleLock;
  
  const _DoorItem({
    required this.door,
    required this.onToggleLock,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: door.isOpen ? AppColors.warningLight : AppColors.safeLight,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(
              door.isOpen ? Icons.door_front_door : Icons.door_front_door,
              color: door.isOpen ? AppColors.warning : AppColors.safe,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  door.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      door.isOpen ? Icons.sensor_door : Icons.door_sliding,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      door.isOpen ? '门已打开' : '门已关闭',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (door.hasCard) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.credit_card,
                        size: 12,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '刷卡门禁',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Icon(
                door.isLocked ? Icons.lock : Icons.lock_open,
                color: door.isLocked ? AppColors.safe : AppColors.warning,
                size: 20,
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => onToggleLock(!door.isLocked),
                child: Text(
                  door.isLocked ? '已锁定' : '未锁定',
                  style: TextStyle(
                    fontSize: 11,
                    color: door.isLocked ? AppColors.safe : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 窗户项
class _WindowItem extends StatelessWidget {
  final WindowInfo window;
  final ValueChanged<bool> onToggle;
  
  const _WindowItem({
    required this.window,
    required this.onToggle,
  });
  
  @override
  Widget build(BuildContext context) {
    return ControlSwitch(
      title: window.name,
      subtitle: window.isOpen ? '开启角度: ${window.openAngle}°' : '已关闭',
      isOn: window.isOpen,
      icon: Icons.window,
      activeColor: AppColors.environment,
      onChanged: onToggle,
    );
  }
}
