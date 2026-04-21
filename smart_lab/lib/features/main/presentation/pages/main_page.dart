import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../alerts/presentation/bloc/alerts_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../chemicals/presentation/bloc/chemicals_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../environment/presentation/bloc/environment_bloc.dart';
import '../../../power/presentation/bloc/power_bloc.dart';
import '../../../security/presentation/bloc/security_bloc.dart';

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
    _NavItem(path: '/', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home'),
    _NavItem(path: '/environment', icon: Icons.air_outlined, activeIcon: Icons.air, label: 'Env'),
    _NavItem(path: '/power', icon: Icons.flash_on_outlined, activeIcon: Icons.flash_on, label: 'Power'),
    _NavItem(path: '/security', icon: Icons.shield_outlined, activeIcon: Icons.shield, label: 'Security'),
    _NavItem(path: '/chemicals', icon: Icons.science_outlined, activeIcon: Icons.science, label: 'Chem'),
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
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.currentLabId != current.currentLabId,
      listener: (context, state) {
        if (state.currentLabId == null) return;
        context.read<DashboardBloc>().add(LoadDashboardData());
        context.read<EnvironmentBloc>().add(LoadEnvironmentData());
        context.read<PowerBloc>().add(LoadPowerData());
        context.read<SecurityBloc>().add(LoadSecurityData());
        context.read<ChemicalsBloc>().add(LoadChemicals());
        context.read<AlertsBloc>().add(LoadAlerts());
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: widget.child,
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      titleSpacing: 12,
      title: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final currentLab = state.currentLab;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shield, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'SmartLab',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                currentLab?.name ?? 'Select lab',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.push('/alerts'),
        ),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return PopupMenuButton<String>(
              tooltip: 'Labs and account',
              onSelected: (value) {
                if (value == 'logout') {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                  context.go('/login');
                  return;
                }
                if (value == 'select-lab') {
                  context.push('/select-lab');
                  return;
                }
                if (state.hasLabAccess(value)) {
                  context.read<AuthBloc>().add(AuthLabChanged(labId: value));
                }
              },
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    enabled: false,
                    value: 'header',
                    child: Text(
                      state.user == null
                          ? 'Not logged in'
                          : '${state.user!.name} - ${state.user!.roleDisplayName}',
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'select-lab',
                    child: Text('Open lab selector'),
                  ),
                ];

                for (final lab in state.accessibleLabs) {
                  items.add(
                    PopupMenuItem<String>(
                      value: lab.id,
                      child: Row(
                        children: [
                          Icon(
                            lab.id == state.currentLabId
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: lab.id == state.currentLabId
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(lab.name)),
                        ],
                      ),
                    ),
                  );
                }

                items.add(const PopupMenuDivider());
                items.add(
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                );
                return items;
              },
              child: const Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.background,
                  child: Icon(Icons.person, size: 20, color: AppColors.textSecondary),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: AppSpacing.bottomNavHeight,
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
                  setState(() => _currentIndex = index);
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
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
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
