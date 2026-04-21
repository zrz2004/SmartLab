import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../bloc/dashboard_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async => context.read<DashboardBloc>().add(RefreshDashboard()),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _ScoreCard(
                score: state.safetyScore,
                labName: state.currentLabName.isEmpty ? 'Current lab' : state.currentLabName,
                alertCount: state.unacknowledgedAlertCount,
                onTap: () => context.push('/alerts'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _QuickCard(
                    title: 'Environment',
                    value: '${state.latestTemperature?.toStringAsFixed(1) ?? '--'} C',
                    color: AppColors.environment,
                    onTap: () => context.go('/environment'),
                  ),
                  _QuickCard(
                    title: 'Power',
                    value: '${state.latestPower?.toStringAsFixed(0) ?? '--'} W',
                    color: AppColors.power,
                    onTap: () => context.go('/power'),
                  ),
                  _QuickCard(
                    title: 'Water',
                    value: 'Normal',
                    color: AppColors.water,
                    onTap: () => context.go('/security'),
                  ),
                  _QuickCard(
                    title: 'Doors',
                    value: 'Review',
                    color: AppColors.security,
                    onTap: () => context.go('/security'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Text('Recent alerts', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Text(state.isMqttConnected ? 'MQTT online' : 'MQTT offline'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.alerts.isEmpty)
                const Text('No alerts')
              else
                ...state.alerts.take(5).map(
                  (alert) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(alert.type.icon),
                    title: Text(alert.title),
                    subtitle: Text(alert.message),
                    trailing: TextButton(
                      onPressed: () => context.read<DashboardBloc>().add(AcknowledgeAlert(alert.id)),
                      child: const Text('Ack'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  final String labName;
  final int alertCount;
  final VoidCallback onTap;

  const _ScoreCard({
    required this.score,
    required this.labName,
    required this.alertCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(labName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text('Safety score: $score'),
            Text('Pending alerts: $alertCount'),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: AppSpacing.sm),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
