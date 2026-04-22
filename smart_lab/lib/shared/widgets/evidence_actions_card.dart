import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/dynamic_text_localizer.dart';
import '../../core/models/ai_inspection_record.dart';
import '../../core/services/evidence_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/alerts/presentation/bloc/alerts_bloc.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';

class EvidenceActionsCard extends StatefulWidget {
  final String title;
  final String description;
  final String labId;
  final String sceneType;
  final String deviceType;
  final String? targetId;

  const EvidenceActionsCard({
    super.key,
    required this.title,
    required this.description,
    required this.labId,
    required this.sceneType,
    required this.deviceType,
    this.targetId,
  });

  @override
  State<EvidenceActionsCard> createState() => _EvidenceActionsCardState();
}

class _EvidenceActionsCardState extends State<EvidenceActionsCard> {
  final EvidenceService _service = getIt<EvidenceService>();
  AiInspectionRecord? _latestInspection;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  @override
  void didUpdateWidget(covariant EvidenceActionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labId != widget.labId ||
        oldWidget.sceneType != widget.sceneType ||
        oldWidget.deviceType != widget.deviceType ||
        oldWidget.targetId != widget.targetId) {
      _loadLatest();
    }
  }

  Future<void> _loadLatest() async {
    await _service.retryPendingUploads();
    final latest = await _service.getLatestInspection(
      labId: widget.labId,
      sceneType: widget.sceneType,
      deviceType: widget.deviceType,
      targetId: widget.targetId,
    );
    if (!mounted) return;
    setState(() => _latestInspection = latest);
  }

  @override
  Widget build(BuildContext context) {
    final inspection = _latestInspection;
    final riskColor = _riskColor(inspection);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(widget.description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading ? null : () => _runCapture(camera: true),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(context.l10n.t('evidence.capture')),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : () => _runCapture(camera: false),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(context.l10n.t('evidence.upload')),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: inspection == null ? null : _showLatestInspection,
            icon: const Icon(Icons.visibility_outlined),
            label: Text(
              inspection == null
                  ? context.l10n.t('evidence.noResult')
                  : context.l10n.t('evidence.showLatest'),
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(),
          ],
          if (inspection != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: riskColor.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Tag(
                        label: DynamicTextLocalizer.riskLevel(
                          context,
                          inspection.riskLevel,
                        ),
                        color: riskColor,
                      ),
                      _Tag(
                        label:
                            '${(inspection.confidence * 100).toStringAsFixed(0)}%',
                        color: AppColors.primary,
                      ),
                      _Tag(
                        label: DynamicTextLocalizer.reviewStatus(
                          context,
                          inspection.reviewStatus,
                        ),
                        color: AppColors.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    DynamicTextLocalizer.reason(context, inspection.reason),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    DynamicTextLocalizer.recommendation(
                      context,
                      inspection.recommendedAction,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _runCapture({required bool camera}) async {
    setState(() => _loading = true);
    final result = camera
        ? await _service.captureAndInspect(
            labId: widget.labId,
            sceneType: widget.sceneType,
            deviceType: widget.deviceType,
            targetId: widget.targetId,
          )
        : await _service.uploadAndInspect(
            labId: widget.labId,
            sceneType: widget.sceneType,
            deviceType: widget.deviceType,
            targetId: widget.targetId,
          );
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result?.inspection != null) {
        _latestInspection = result!.inspection;
      }
    });

    if (result == null) return;

    context.read<AlertsBloc>().add(LoadAlerts());
    context.read<DashboardBloc>().add(RefreshDashboard());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );

    final risk = result.inspection?.riskLevel.toLowerCase();
    if (risk == 'warning' || risk == 'critical') {
      await _showInspectionWarning(result.inspection!);
    }
  }

  Future<void> _showInspectionWarning(AiInspectionRecord inspection) async {
    final isCritical = inspection.riskLevel.toLowerCase() == 'critical';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              isCritical
                  ? Icons.warning_amber_rounded
                  : Icons.notification_important_rounded,
              color: isCritical ? AppColors.critical : AppColors.warning,
            ),
            const SizedBox(width: 8),
            Text(isCritical ? '严重警告' : '安全预警'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DynamicTextLocalizer.reason(context, inspection.reason),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              DynamicTextLocalizer.recommendation(
                context,
                inspection.recommendedAction,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.t('common.ok')),
          ),
        ],
      ),
    );
  }

  void _showLatestInspection() {
    final inspection = _latestInspection;
    if (inspection == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.t('evidence.latestTitle'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: _riskColor(inspection).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _riskColor(inspection).withValues(alpha: 0.24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DynamicTextLocalizer.riskLevel(
                        context,
                        inspection.riskLevel,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _riskColor(inspection),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DynamicTextLocalizer.reason(context, inspection.reason),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (inspection.mediaUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    inspection.mediaUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      width: double.infinity,
                      color: AppColors.background,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _InspectionRow(
                label: context.l10n.t('evidence.scene'),
                value: DynamicTextLocalizer.sceneType(
                  context,
                  inspection.sceneType,
                ),
              ),
              _InspectionRow(
                label: context.l10n.t('evidence.device'),
                value: DynamicTextLocalizer.deviceType(
                  context,
                  inspection.deviceType,
                ),
              ),
              _InspectionRow(
                label: context.l10n.t('evidence.risk'),
                value: DynamicTextLocalizer.riskLevel(
                  context,
                  inspection.riskLevel,
                ),
              ),
              _InspectionRow(
                label: context.l10n.t('evidence.confidence'),
                value: '${(inspection.confidence * 100).toStringAsFixed(0)}%',
              ),
              _InspectionRow(
                label: context.l10n.t('evidence.model'),
                value: inspection.model,
              ),
              _InspectionRow(
                label: context.l10n.t('evidence.review'),
                value: DynamicTextLocalizer.reviewStatus(
                  context,
                  inspection.reviewStatus,
                ),
              ),
              _InspectionRow(
                label: '时间',
                value:
                    '${inspection.capturedAt.year}-${inspection.capturedAt.month.toString().padLeft(2, '0')}-${inspection.capturedAt.day.toString().padLeft(2, '0')} '
                    '${inspection.capturedAt.hour.toString().padLeft(2, '0')}:${inspection.capturedAt.minute.toString().padLeft(2, '0')}',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.t(
                  'evidence.action',
                  params: {
                    'value': DynamicTextLocalizer.recommendation(
                      context,
                      inspection.recommendedAction,
                    ),
                  },
                ),
              ),
              if (inspection.evidence.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text('识别依据', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                ...inspection.evidence.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text('•'),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            DynamicTextLocalizer.evidenceItem(context, item),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _riskColor(AiInspectionRecord? inspection) {
    switch (inspection?.riskLevel.toLowerCase()) {
      case 'critical':
        return AppColors.critical;
      case 'warning':
        return AppColors.warning;
      default:
        return AppColors.safe;
    }
  }
}

class _InspectionRow extends StatelessWidget {
  final String label;
  final String value;

  const _InspectionRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 88, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
