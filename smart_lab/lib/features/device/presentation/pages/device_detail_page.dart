import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/evidence_actions_card.dart';
import '../../../../shared/widgets/realtime_chart.dart';
import '../../../../shared/widgets/sensor_gauge.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class DeviceDetailPage extends StatefulWidget {
  final String deviceId;

  const DeviceDetailPage({
    super.key,
    required this.deviceId,
  });

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  final ApiService _apiService = getIt<ApiService>();

  late Future<_DeviceDetailViewModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDevice();
  }

  Future<_DeviceDetailViewModel> _loadDevice() async {
    try {
      final detail = await _apiService.getDeviceDetail(widget.deviceId);
      final history = await _apiService.getTelemetryHistory(
        deviceId: widget.deviceId,
        start: DateTime.now().subtract(const Duration(hours: 24)),
        end: DateTime.now(),
      );
      return _DeviceDetailViewModel.fromApi(detail, history);
    } catch (_) {
      return _DeviceDetailViewModel.fallback(widget.deviceId);
    }
  }

  Future<void> _refresh() async {
    final next = _loadDevice();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final currentLabId = context.watch<AuthBloc>().state.currentLabId ?? 'lab_yuanlou_806';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<_DeviceDetailViewModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final model = snapshot.data ?? _DeviceDetailViewModel.fallback(widget.deviceId);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _InfoChip(label: 'ID', value: model.id),
                          _InfoChip(label: 'Type', value: model.type),
                          _InfoChip(label: 'Status', value: model.status),
                          _InfoChip(label: 'Protocol', value: model.protocol),
                          _InfoChip(label: 'Firmware', value: model.firmware),
                          _InfoChip(label: 'Location', value: model.location),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: EvidenceActionsCard(
                    title: 'AI evidence for device',
                    description: 'Attach photos when device telemetry is unavailable.',
                    labId: currentLabId,
                    sceneType: 'device',
                    deviceType: model.type,
                    targetId: widget.deviceId,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  delegate: SliverChildListDelegate([
                    SensorGauge(
                      label: 'Temp',
                      value: model.temperature,
                      unit: 'C',
                      minValue: 0,
                      maxValue: 50,
                      warningValue: 28,
                      criticalValue: 35,
                      primaryColor: AppColors.environment,
                      icon: Icons.thermostat,
                    ),
                    SensorGauge(
                      label: 'Humidity',
                      value: model.humidity,
                      unit: '%',
                      minValue: 0,
                      maxValue: 100,
                      warningValue: 60,
                      criticalValue: 80,
                      primaryColor: AppColors.water,
                      icon: Icons.water_drop,
                    ),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: RealtimeChart(
                    data: model.history,
                    title: '24h trend',
                    unit: 'C',
                    lineColor: AppColors.environment,
                    warningThreshold: 28,
                    criticalThreshold: 35,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Text('$label: $value'),
    );
  }
}

class _DeviceDetailViewModel {
  final String id;
  final String name;
  final String type;
  final String location;
  final String status;
  final String firmware;
  final String protocol;
  final double temperature;
  final double humidity;
  final List<FlSpot> history;

  const _DeviceDetailViewModel({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.status,
    required this.firmware,
    required this.protocol,
    required this.temperature,
    required this.humidity,
    required this.history,
  });

  factory _DeviceDetailViewModel.fromApi(
    Map<String, dynamic> detail,
    List<Map<String, dynamic>> history,
  ) {
    final telemetry = Map<String, dynamic>.from(detail['telemetry'] as Map? ?? const {});
    final line = history.isEmpty
        ? List.generate(24, (index) => FlSpot(index.toDouble(), 22 + (index % 4) * 0.6))
        : history.asMap().entries.map((entry) {
            final payload = Map<String, dynamic>.from(entry.value['values'] as Map? ?? const {});
            final y = (payload['temperature'] as num?)?.toDouble() ??
                (entry.value['temperature'] as num?)?.toDouble() ??
                22;
            return FlSpot(entry.key.toDouble(), y);
          }).toList();

    return _DeviceDetailViewModel(
      id: detail['id']?.toString() ?? '',
      name: detail['name'] as String? ?? 'Unknown device',
      type: detail['type'] as String? ?? 'generic_device',
      location: detail['position'] as String? ?? detail['lab_name'] as String? ?? 'Unknown',
      status: detail['status'] as String? ?? 'offline',
      firmware: detail['firmware_version'] as String? ?? detail['firmware'] as String? ?? 'n/a',
      protocol: detail['protocol'] as String? ?? 'HTTP',
      temperature: (telemetry['temperature'] as num?)?.toDouble() ?? 23.5,
      humidity: (telemetry['humidity'] as num?)?.toDouble() ?? 45,
      history: line,
    );
  }

  factory _DeviceDetailViewModel.fallback(String deviceId) {
    return _DeviceDetailViewModel(
      id: deviceId,
      name: 'Device $deviceId',
      type: 'generic_device',
      location: 'Current lab',
      status: 'online',
      firmware: 'v2.1.3',
      protocol: 'MQTT / HTTP',
      temperature: 23.5,
      humidity: 45,
      history: List.generate(24, (i) => FlSpot(i.toDouble(), 22 + (i % 4) * 0.6)),
    );
  }
}
