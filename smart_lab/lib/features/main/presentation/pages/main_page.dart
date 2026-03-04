import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// 主页面框架
/// 
/// 包含底部导航栏，承载各个功能模块页面
class MainPage extends StatefulWidget {
  final Widget child;
  
  const MainPage({
    super.key,
    required this.child,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  
  final List<_NavItem> _navItems = const [
    _NavItem(
      path: '/',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: '首页',
    ),
    _NavItem(
      path: '/environment',
      icon: Icons.air_outlined,
      activeIcon: Icons.air,
      label: '环境',
    ),
    _NavItem(
      path: '/power',
      icon: Icons.flash_on_outlined,
      activeIcon: Icons.flash_on,
      label: '电源',
    ),
    _NavItem(
      path: '/security',
      icon: Icons.shield_outlined,
      activeIcon: Icons.shield,
      label: '安防',
    ),
    _NavItem(
      path: '/chemicals',
      icon: Icons.science_outlined,
      activeIcon: Icons.science,
      label: '危化品',
    ),
  ];
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentIndex();
  }
  
  void _updateCurrentIndex() {
    final location = GoRouterState.of(context).uri.path;
    final index = _navItems.indexWhere((item) => item.path == location);
    if (index != -1 && index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: widget.child,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }
  
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shield,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '智慧实验室',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '安全监测与预警系统',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // 报警按钮
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push('/alerts'),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.critical,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // 用户头像
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: GestureDetector(
            onTap: () {
              // TODO: 打开用户菜单
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.background,
              child: Icon(
                Icons.person,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: AppSpacing.bottomNavHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == _currentIndex;
              
              return _NavButton(
                item: item,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                  context.go(item.path);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// 导航项数据
class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  
  const _NavItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// 导航按钮
class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 24,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
