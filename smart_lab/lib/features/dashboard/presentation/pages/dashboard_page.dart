import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/dynamic_text_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../bloc/dashboard_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async => context.read<DashboardBloc>().add(RefreshDashboard()),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _ScoreCard(
                score: state.safetyScore,
                labName: state.currentLabName.isEmpty ? l10n.t('dashboard.currentLab') : state.currentLabName,
                labSubtitle: state.currentLabSubtitle,
                alertCount: state.unacknowledgedAlertCount,
                onTap: () => context.push('/alerts'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _QuickCard(
                    title: l10n.t('dashboard.environment'),
                    value: _localizedOverviewStatus(context, state.environmentStatus),
                    secondary: state.latestTemperature == null
                        ? (state.latestHumidity == null ? 'AI 巡检为主' : '${state.latestHumidity!.toStringAsFixed(1)} %RH')
                        : '${state.latestTemperature!.toStringAsFixed(1)} C',
                    color: AppColors.environment,
                    onTap: () => context.go('/environment'),
                  ),
                  _QuickCard(
                    title: l10n.t('dashboard.power'),
                    value: _localizedOverviewStatus(context, state.powerStatus),
                    secondary: state.latestPower == null
                        ? 'AI 电源复核'
                        : '${state.latestPower!.toStringAsFixed(0)} W',
                    color: AppColors.power,
                    onTap: () => context.go('/power'),
                  ),
                  _QuickCard(
                    title: l10n.t('dashboard.water'),
                    value: _localizedOverviewStatus(context, state.waterStatus),
                    secondary: '水源与渗漏',
                    color: AppColors.water,
                    onTap: () => context.go('/security'),
                  ),
                  _QuickCard(
                    title: l10n.t('dashboard.doors'),
                    value: _localizedOverviewStatus(context, state.doorStatus),
                    secondary: '门窗与门锁',
                    color: AppColors.security,
                    onTap: () => context.go('/security'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.borderRadiusLg,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _InfoMetric(
                        label: 'Humidity',
                        value: '${state.latestHumidity?.toStringAsFixed(1) ?? '--'} %',
                      ),
                    ),
                    Expanded(
                      child: _InfoMetric(
                        label: 'VOC',
                        value: state.latestVoc?.toStringAsFixed(0) ?? '--',
                      ),
                    ),
                    Expanded(
                      child: _InfoMetric(
                        label: 'Updated',
                        value: state.lastUpdateTime == null
                            ? '--'
                            : '${state.lastUpdateTime!.hour.toString().padLeft(2, '0')}:${state.lastUpdateTime!.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Text(l10n.t('dashboard.recentAlerts'), style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Text(state.isMqttConnected ? l10n.t('dashboard.mqttOnline') : l10n.t('dashboard.mqttOffline')),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.alerts.isEmpty)
                Text(l10n.t('dashboard.noAlerts'))
              else
                ...state.alerts.take(5).map(
                  (alert) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(alert.type.icon),
                    title: Text(DynamicTextLocalizer.alertTitle(context, alert.title)),
                    subtitle: Text(DynamicTextLocalizer.alertMessage(context, alert.message)),
                    trailing: TextButton(
                      onPressed: () => context.read<DashboardBloc>().add(AcknowledgeAlert(alert.id)),
                      child: Text(l10n.t('dashboard.ack')),
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

class _InfoMetric extends StatelessWidget {
  final String label;
  final String value;

  const _InfoMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  final String labName;
  final String labSubtitle;
  final int alertCount;
  final VoidCallback onTap;

  const _ScoreCard({
    required this.score,
    required this.labName,
    required this.labSubtitle,
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
            if (labSubtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                labSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(context.l10n.t('dashboard.safetyScore', params: {'score': '$score'})),
            Text(context.l10n.t('dashboard.pendingAlerts', params: {'count': '$alertCount'})),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final String value;
  final String secondary;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({
    required this.title,
    required this.value,
    required this.secondary,
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
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _statusColor(value, color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                secondary,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String value, Color defaultColor) {
    final normalized = value.toLowerCase();
    if (normalized.contains('严重')) return AppColors.critical;
    if (normalized.contains('预警')) return AppColors.warning;
    if (normalized.contains('正常')) return AppColors.safe;
    return defaultColor;
  }
}

String _localizedOverviewStatus(BuildContext context, String raw) {
  switch (raw.toLowerCase()) {
    case 'normal':
      return context.l10n.t('dashboard.normal');
    case 'warning':
      return '预警';
    case 'critical':
      return '严重';
    case 'review':
      return context.l10n.t('dashboard.review');
    default:
      return raw;
  }
}
