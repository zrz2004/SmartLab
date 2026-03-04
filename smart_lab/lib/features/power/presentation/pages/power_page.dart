import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/control_switch.dart';
import '../bloc/power_bloc.dart';

/// 电源管理页面
class PowerPage extends StatefulWidget {
  const PowerPage({super.key});

  @override
  State<PowerPage> createState() => _PowerPageState();
}

class _PowerPageState extends State<PowerPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  @override
  void initState() {
    super.initState();
    context.read<PowerBloc>().add(LoadPowerData());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PowerBloc, PowerState>(
      builder: (context, state) {
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 页面标题
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  '智能电源管理',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            
            // 主电源控制卡片
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _MainPowerCard(
                  isOn: state.isMainPowerOn,
                  power: state.currentPower ?? 0,
                  voltage: state.currentVoltage ?? 220,
                  isControlling: state.isControlling,
                  onToggle: () => _handleMainPowerToggle(context, state),
                ),
              ),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.lg),
            ),
            
            // 漏电流监测
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _LeakageCard(
                  leakageCurrent: state.leakageCurrent ?? 0,
                ),
              ),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.lg),
            ),
            
            // 插座列表标题
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '插座状态',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Modbus 协议',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.md),
            ),
            
            // 插座列表
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final socket = state.sockets[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _SocketItem(
                        socket: socket,
                        onToggle: (value) {
                          context.read<PowerBloc>().add(
                            ToggleSocket(socket.id, value),
                          );
                        },
                      ),
                    );
                  },
                  childCount: state.sockets.length,
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
  
  Future<void> _handleMainPowerToggle(BuildContext context, PowerState state) async {
    final newValue = !state.isMainPowerOn;
    
    // 关闭主电源需要二次确认和生物识别
    if (!newValue) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认断电'),
          content: const Text(
            '您正在尝试切断 302 实验室的主电源，请确认环境安全！\n\n'
            '此操作将导致所有设备断电，实验中的设备可能受到影响。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.critical,
              ),
              child: const Text('确认断电'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
      
      // 生物识别验证
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: '请验证身份以执行断电操作',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
        
        if (!authenticated) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('身份验证失败')),
            );
          }
          return;
        }
      } catch (e) {
        // 设备不支持生物识别，继续执行
      }
    }
    
    if (context.mounted) {
      context.read<PowerBloc>().add(ToggleMainPower(newValue));
    }
  }
}

/// 主电源控制卡片
class _MainPowerCard extends StatelessWidget {
  final bool isOn;
  final double power;
  final double voltage;
  final bool isControlling;
  final VoidCallback onToggle;
  
  const _MainPowerCard({
    required this.isOn,
    required this.power,
    required this.voltage,
    required this.isControlling,
    required this.onToggle,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: isOn ? AppColors.powerGradient : null,
        color: isOn ? null : AppColors.textTertiary,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: (isOn ? AppColors.power : AppColors.textTertiary).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前功率',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isOn ? power.toStringAsFixed(0) : '0',
                        style: const TextStyle(
                          fontFamily: 'DINAlternate',
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'W',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOn ? Icons.flash_on : Icons.flash_off,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // 电压显示
          Row(
            children: [
              Icon(
                Icons.electrical_services,
                size: 16,
                color: Colors.white.withOpacity(0.8),
              ),
              const SizedBox(width: 4),
              Text(
                '电压: ${voltage.toStringAsFixed(1)} V',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // 控制按钮
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isControlling ? null : onToggle,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: isOn ? AppColors.critical : AppColors.safe,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: isControlling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isOn ? '紧急断电' : '恢复供电',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 漏电流监测卡片
class _LeakageCard extends StatelessWidget {
  final double leakageCurrent;
  
  const _LeakageCard({required this.leakageCurrent});
  
  @override
  Widget build(BuildContext context) {
    final isWarning = leakageCurrent >= 15;
    final isCritical = leakageCurrent >= 30;
    
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: isCritical 
            ? AppColors.criticalLight 
            : isWarning 
                ? AppColors.warningLight 
                : Colors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isCritical 
              ? AppColors.critical.withOpacity(0.3) 
              : isWarning 
                  ? AppColors.warning.withOpacity(0.3) 
                  : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isCritical 
                  ? AppColors.critical.withOpacity(0.2) 
                  : isWarning 
                      ? AppColors.warning.withOpacity(0.2) 
                      : AppColors.safeLight,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(
              Icons.warning_rounded,
              color: isCritical 
                  ? AppColors.critical 
                  : isWarning 
                      ? AppColors.warning 
                      : AppColors.safe,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '漏电流监测',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  isCritical 
                      ? '危险！请立即检查' 
                      : isWarning 
                          ? '注意：接近安全阈值' 
                          : '状态正常',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${leakageCurrent.toStringAsFixed(1)} mA',
                style: TextStyle(
                  fontFamily: 'DINAlternate',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isCritical 
                      ? AppColors.critical 
                      : isWarning 
                          ? AppColors.warning 
                          : AppColors.safe,
                ),
              ),
              Text(
                '阈值: 30 mA',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 插座项
class _SocketItem extends StatelessWidget {
  final SocketInfo socket;
  final ValueChanged<bool> onToggle;
  
  const _SocketItem({
    required this.socket,
    required this.onToggle,
  });
  
  @override
  Widget build(BuildContext context) {
    return ControlSwitch(
      title: socket.name,
      subtitle: socket.isOn ? '${socket.power.toStringAsFixed(0)} W' : '已关闭',
      isOn: socket.isOn,
      icon: Icons.power,
      activeColor: AppColors.power,
      onChanged: onToggle,
    );
  }
}
