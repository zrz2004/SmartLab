import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/models/ai_inspection_record.dart';
import '../../core/services/evidence_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

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

  Future<void> _loadLatest() async {
    final latest = await _service.getLatestInspection(
      labId: widget.labId,
      sceneType: widget.sceneType,
      deviceType: widget.deviceType,
      targetId: widget.targetId,
    );
    if (mounted) setState(() => _latestInspection = latest);
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

  @override
  Widget build(BuildContext context) {
    final inspection = _latestInspection;
    final riskColor = switch (inspection?.riskLevel) {
      'critical' => AppColors.critical,
      'warning' => AppColors.warning,
      _ => AppColors.info,
    };

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
                  label: const Text('Capture'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : () => _runCapture(camera: false),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Upload'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: inspection == null ? null : _showLatestInspection,
            icon: const Icon(Icons.visibility_outlined),
            label: Text(inspection == null ? 'No AI result yet' : 'Show latest AI result'),
          ),
          if (_loading) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(),
          ],
          if (inspection != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${inspection.riskLevel.toUpperCase()} - ${inspection.model}\n${inspection.reason}',
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
      if (result?.inspection != null) _latestInspection = result!.inspection;
    });
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  void _showLatestInspection() {
    final inspection = _latestInspection;
    if (inspection == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latest AI inspection', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            _InspectionRow(label: 'Scene', value: inspection.sceneType),
            _InspectionRow(label: 'Device', value: inspection.deviceType),
            _InspectionRow(label: 'Risk', value: inspection.riskLevel),
            _InspectionRow(
              label: 'Confidence',
              value: '${(inspection.confidence * 100).toStringAsFixed(0)}%',
            ),
            _InspectionRow(label: 'Model', value: inspection.model),
            _InspectionRow(label: 'Review', value: inspection.reviewStatus),
            const SizedBox(height: AppSpacing.sm),
            Text(inspection.reason),
            const SizedBox(height: AppSpacing.sm),
            Text('Action: ${inspection.recommendedAction}'),
          ],
        ),
      ),
    );
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
        children: [
          SizedBox(width: 88, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
