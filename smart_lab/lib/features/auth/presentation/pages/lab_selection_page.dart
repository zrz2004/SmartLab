import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/lab_config.dart';
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
                    'Select Lab',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This release is limited to the two labs defined in project docs.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (state.user != null)
                    Text('${state.user!.name} (${state.user!.roleDisplayName})'),
                  const SizedBox(height: 32),
                  Expanded(
                    child: labs.isEmpty
                        ? const Center(child: Text('No lab access assigned'))
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
                      label: const Text('Logout'),
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
          color: selected ? AppColors.primaryLight.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lab.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${lab.buildingName} · ${lab.floor} · ${lab.roomNumber}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Env ${LabConfig.getDeviceCountByType(lab.id, 'environmentSensor')}'),
                _chip('Socket ${LabConfig.getDeviceCountByType(lab.id, 'smartSocket')}'),
                _chip('Door ${LabConfig.getDeviceCountByType(lab.id, 'doorSensor')}'),
                _chip('Window ${LabConfig.getDeviceCountByType(lab.id, 'windowSensor')}'),
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
