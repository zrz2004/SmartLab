import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/dynamic_text_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/evidence_actions_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/alert.dart';
import '../bloc/alerts_bloc.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AlertsBloc>().add(LoadAlerts());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final authState = context.watch<AuthBloc>().state;
    final currentLabId = authState.currentLabId ?? 'lab_yuanlou_806';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('alerts.title')),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: BlocBuilder<AlertsBloc, AlertsState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: EvidenceActionsCard(
                  title: l10n.t('alerts.evidenceTitle'),
                  description: l10n.t('alerts.evidenceDesc'),
                  labId: currentLabId,
                  sceneType: 'alert',
                  deviceType: 'alert_center',
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: state.filteredAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = state.filteredAlerts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _AlertCard(
                        alert: alert,
                        canAcknowledge: authState.canAcknowledgeAlerts,
                        onAcknowledge: () => context.read<AlertsBloc>().add(AcknowledgeAlert(alert.id)),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;
  final bool canAcknowledge;
  final VoidCallback onAcknowledge;

  const _AlertCard({
    required this.alert,
    required this.canAcknowledge,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final localizedTitle = DynamicTextLocalizer.alertTitle(context, alert.title);
    final localizedMessage = DynamicTextLocalizer.alertMessage(context, alert.message);
    final color = switch (alert.level) {
      AlertLevel.critical => AppColors.critical,
      AlertLevel.warning => AppColors.warning,
      AlertLevel.info => AppColors.info,
    };
    final isAi = alert.snapshot?['source'] == 'ai';

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: alert.isAcknowledged ? Colors.white : color.withValues(alpha: 0.08),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(alert.type.icon, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(localizedTitle)),
              if (isAi) Text(context.l10n.t('alerts.ai')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(localizedMessage),
          const SizedBox(height: AppSpacing.sm),
          Text(alert.deviceName, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text('${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}'),
              const Spacer(),
              if (!alert.isAcknowledged)
                TextButton(onPressed: canAcknowledge ? onAcknowledge : null, child: Text(context.l10n.t('alerts.ack')))
              else
                Text(context.l10n.t('alerts.acked')),
            ],
          ),
        ],
      ),
    );
  }
}
