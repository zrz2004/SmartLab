import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/control_switch.dart';
import '../../../../shared/widgets/evidence_actions_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/power_bloc.dart';

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
        final l10n = context.l10n;
        final authState = context.watch<AuthBloc>().state;
        final currentLabId = authState.currentLabId ?? 'lab_yuanlou_806';
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(l10n.t('power.title'), style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: EvidenceActionsCard(
                  title: l10n.t('power.evidenceTitle'),
                  description: l10n.t('power.evidenceDesc'),
                  labId: currentLabId,
                  sceneType: 'power',
                  deviceType: 'main_power',
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _MainPowerCard(
                  isOn: state.isMainPowerOn,
                  power: state.currentPower ?? 0,
                  voltage: state.currentVoltage ?? 220,
                  isControlling: state.isControlling,
                  canControl: authState.canControlDevices,
                  onToggle: () => _handleMainPowerToggle(context, state),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  l10n.t(
                    'power.leakage',
                    params: {'value': state.leakageCurrent?.toStringAsFixed(1) ?? '0.0'},
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final socket = state.sockets[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ControlSwitch(
                        title: socket.name,
                        subtitle: socket.isOn
                            ? '${socket.power.toStringAsFixed(0)} W'
                          : l10n.t('common.off'),
                        isOn: socket.isOn,
                        icon: Icons.power,
                        activeColor: AppColors.power,
                        onChanged: authState.canControlDevices
                            ? (value) => context.read<PowerBloc>().add(ToggleSocket(socket.id, value))
                            : null,
                      ),
                    );
                  },
                  childCount: state.sockets.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleMainPowerToggle(BuildContext context, PowerState state) async {
    final l10n = context.l10n;
    if (!context.read<AuthBloc>().state.canControlDevices) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('power.noPermission'))),
      );
      return;
    }

    final newValue = !state.isMainPowerOn;
    if (!newValue) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.t('power.confirmShutdownTitle')),
          content: Text(l10n.t('power.confirmShutdownDesc')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.t('common.cancel'))),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.t('common.confirm'))),
          ],
        ),
      );
      if (confirmed != true) return;
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: l10n.t('power.biometricReason'),
          options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
        );
        if (!authenticated) return;
      } catch (_) {}
    }
    if (context.mounted) context.read<PowerBloc>().add(ToggleMainPower(newValue));
  }
}

class _MainPowerCard extends StatelessWidget {
  final bool isOn;
  final double power;
  final double voltage;
  final bool isControlling;
  final bool canControl;
  final VoidCallback onToggle;

  const _MainPowerCard({
    required this.isOn,
    required this.power,
    required this.voltage,
    required this.isControlling,
    required this.canControl,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.t('power.powerValue', params: {'value': isOn ? power.toStringAsFixed(0) : '0'}),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.t('power.voltageValue', params: {'value': voltage.toStringAsFixed(1)}),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: !canControl || isControlling ? null : onToggle,
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
              child: isControlling
                  ? const CircularProgressIndicator()
                  : Text(isOn ? context.l10n.t('power.shutdown') : context.l10n.t('power.restore')),
            ),
          ),
        ],
      ),
    );
  }
}
