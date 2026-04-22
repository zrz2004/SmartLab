import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/control_switch.dart';
import '../../../../shared/widgets/evidence_actions_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/security_bloc.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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
        final l10n = context.l10n;
        final authState = context.watch<AuthBloc>().state;
        final currentLabId = authState.currentLabId ?? 'lab_yuanlou_806';
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: TabBar(
                controller: _tabController,
                tabs: [Tab(text: l10n.t('security.tabWater')), Tab(text: l10n.t('security.tabDoors'))],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    children: [
                      EvidenceActionsCard(
                        title: l10n.t('security.waterEvidenceTitle'),
                        description: l10n.t('security.waterEvidenceDesc'),
                        labId: currentLabId,
                        sceneType: 'water',
                        deviceType: 'main_valve',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ControlSwitch(
                        title: l10n.t('security.mainValve'),
                        subtitle: state.mainValveOpen ? l10n.t('security.open') : l10n.t('security.closed'),
                        isOn: state.mainValveOpen,
                        icon: Icons.water_drop,
                        activeColor: AppColors.water,
                        onChanged: authState.canControlDevices
                            ? (value) => context.read<SecurityBloc>().add(ToggleWaterValve(value))
                            : null,
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    children: [
                      EvidenceActionsCard(
                        title: l10n.t('security.doorsEvidenceTitle'),
                        description: l10n.t('security.doorsEvidenceDesc'),
                        labId: currentLabId,
                        sceneType: 'security',
                        deviceType: 'door_window',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ...state.doors.map(
                        (door) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ControlSwitch(
                            title: door.name,
                            subtitle: door.isLocked ? l10n.t('security.locked') : l10n.t('security.unlocked'),
                            isOn: door.isLocked,
                            icon: Icons.door_front_door_outlined,
                            activeColor: AppColors.security,
                            onChanged: authState.canControlDevices
                                ? (value) => context.read<SecurityBloc>().add(ToggleDoor(door.id, value))
                                : null,
                          ),
                        ),
                      ),
                      ...state.windows.map(
                        (window) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ControlSwitch(
                            title: window.name,
                            subtitle: window.isOpen
                                ? l10n.t('security.windowAngle', params: {'angle': '${window.openAngle}'})
                                : l10n.t('security.closed'),
                            isOn: window.isOpen,
                            icon: Icons.window_outlined,
                            activeColor: AppColors.environment,
                            onChanged: authState.canControlDevices
                                ? (value) => context.read<SecurityBloc>().add(ToggleWindow(window.id, value))
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
