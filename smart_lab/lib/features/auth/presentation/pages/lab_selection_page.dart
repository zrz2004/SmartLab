import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/lab_config.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';

class LabSelectionPage extends StatelessWidget {
  const LabSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated && state.currentLabId != null) {
          context.go('/');
        }
      },
      builder: (context, state) {
        final l10n = context.l10n;
        final labs = state.accessibleLabs;

        if (labs.length == 1 && state.currentLabId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AuthBloc>().add(AuthLabChanged(labId: labs.first.id));
          });
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    l10n.t('labSelection.title'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.t('labSelection.desc'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (state.user != null)
                    Text(
                      '${state.user!.name} · ${l10n.t('role.${state.user!.role.name}')}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: labs.isEmpty
                        ? Center(child: Text(l10n.t('labSelection.noAccess')))
                        : ListView.separated(
                            itemCount: labs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final lab = labs[index];
                              final selected = lab.id == state.currentLabId;
                              return _LabCard(
                                lab: lab,
                                selected: selected,
                                onTap: () => context.read<AuthBloc>().add(
                                      AuthLabChanged(labId: lab.id),
                                    ),
                              );
                            },
                          ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(const AuthLogoutRequested());
                        context.go('/login');
                      },
                      icon: const Icon(Icons.logout),
                      label: Text(l10n.t('common.logout')),
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
}

class _LabCard extends StatelessWidget {
  final LabInfo lab;
  final bool selected;
  final VoidCallback onTap;

  const _LabCard({
    required this.lab,
    required this.selected,
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
          color: selected ? AppColors.primaryLight.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lab.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              lab.englishName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${lab.buildingName} · ${lab.floor} · ${lab.roomNumber}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  context.l10n.t(
                    'labSelection.envCount',
                    params: {
                      'count': '${LabConfig.getDeviceCountByType(lab.id, 'environmentSensor')}',
                    },
                  ),
                ),
                _chip(
                  context.l10n.t(
                    'labSelection.socketCount',
                    params: {
                      'count': '${LabConfig.getDeviceCountByType(lab.id, 'smartSocket')}',
                    },
                  ),
                ),
                _chip(
                  context.l10n.t(
                    'labSelection.doorCount',
                    params: {
                      'count': '${LabConfig.getDeviceCountByType(lab.id, 'doorSensor')}',
                    },
                  ),
                ),
                _chip(
                  context.l10n.t(
                    'labSelection.windowCount',
                    params: {
                      'count': '${LabConfig.getDeviceCountByType(lab.id, 'windowSensor')}',
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
