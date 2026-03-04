import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/lab_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';

/// 实验室选择页面
/// 
/// 用户登录成功后，需要选择要管理的实验室
/// 只显示用户有权限访问的实验室
class LabSelectionPage extends StatelessWidget {
  const LabSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // 如果用户选择了实验室，跳转到主页
        if (state.status == AuthStatus.authenticated && state.selectedLabId != null) {
          context.go('/');
        }
      },
      builder: (context, state) {
        final accessibleLabs = state.user?.accessibleLabIds ?? [];
        final labs = LabConfig.labs.where(
          (lab) => accessibleLabs.contains(lab.id),
        ).toList();
        
        // 如果用户只有一个实验室权限，直接选择并跳转
        if (labs.length == 1 && state.selectedLabId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AuthBloc>().add(AuthLabChanged(labs.first.id));
          });
        }
        
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  
                  // 标题
                  Text(
                    '选择实验室',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 副标题
                  Text(
                    '请选择您要管理的实验室',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 用户信息
                  if (state.user != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${state.user!.name} (${state.user!.roleDisplayName})',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // 实验室列表
                  Expanded(
                    child: labs.isEmpty
                        ? _buildEmptyState(context)
                        : _buildLabList(context, labs, state.selectedLabId),
                  ),
                  
                  // 退出登录按钮
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                        context.go('/login');
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('退出登录'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.textSecondary),
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无可访问的实验室',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请联系管理员分配实验室权限',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLabList(
    BuildContext context,
    List<LabInfo> labs,
    String? selectedLabId,
  ) {
    return ListView.separated(
      itemCount: labs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final lab = labs[index];
        final isSelected = lab.id == selectedLabId;
        final building = LabConfig.getBuilding(lab.buildingId);
        
        return _LabCard(
          lab: lab,
          buildingName: building?.name ?? '未知楼栋',
          isSelected: isSelected,
          onTap: () {
            context.read<AuthBloc>().add(AuthLabChanged(lab.id));
          },
        );
      },
    );
  }
}

/// 实验室卡片组件
class _LabCard extends StatelessWidget {
  final LabInfo lab;
  final String buildingName;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _LabCard({
    required this.lab,
    required this.buildingName,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：图标和选中状态
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getLabColor(lab.id).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.science,
                    color: _getLabColor(lab.id),
                    size: 28,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '已选择',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 实验室名称
            Text(
              lab.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 楼栋和楼层信息
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$buildingName · ${lab.floor}楼',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 设备统计
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildDeviceStat(
                  icon: Icons.sensors,
                  label: '传感器',
                  count: lab.devices.where((d) => d.type == DeviceType.sensor).length,
                ),
                _buildDeviceStat(
                  icon: Icons.power,
                  label: '插座',
                  count: lab.devices.where((d) => d.type == DeviceType.socket).length,
                ),
                _buildDeviceStat(
                  icon: Icons.door_front_door_outlined,
                  label: '门',
                  count: lab.devices.where((d) => d.type == DeviceType.door).length,
                ),
                _buildDeviceStat(
                  icon: Icons.window_outlined,
                  label: '窗户',
                  count: lab.devices.where((d) => d.type == DeviceType.window).length,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeviceStat({
    required IconData icon,
    required String label,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            '$label $count',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getLabColor(String labId) {
    if (labId.contains('yuanlou')) {
      return AppColors.primary;
    } else if (labId.contains('xixue')) {
      return AppColors.info;
    }
    return AppColors.primary;
  }
}
