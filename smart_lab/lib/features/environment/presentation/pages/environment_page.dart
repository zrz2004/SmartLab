import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/safety_thresholds.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/evidence_actions_card.dart';
import '../../../../shared/widgets/realtime_chart.dart';
import '../../../../shared/widgets/sensor_gauge.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/environment_bloc.dart';

class EnvironmentPage extends StatefulWidget {
  const EnvironmentPage({super.key});

  @override
  State<EnvironmentPage> createState() => _EnvironmentPageState();
}

class _EnvironmentPageState extends State<EnvironmentPage> {
  @override
  void initState() {
    super.initState();
    context.read<EnvironmentBloc>().add(LoadEnvironmentData());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EnvironmentBloc, EnvironmentState>(
      builder: (context, state) {
        final currentLabId = context.watch<AuthBloc>().state.currentLabId ?? 'lab_yuanlou_806';
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text('Environment', style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: EvidenceActionsCard(
                  title: 'AI evidence for environment',
                  description: 'Use image review when hardware sensors are unavailable.',
                  labId: currentLabId,
                  sceneType: 'environment',
                  deviceType: 'environment_sensor',
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
                    value: state.currentTemperature ?? 24.0,
                    unit: 'C',
                    minValue: 0,
                    maxValue: 50,
                    warningValue: SafetyThresholds.tempWarningMax,
                    criticalValue: SafetyThresholds.tempCriticalMax,
                    primaryColor: AppColors.environment,
                    icon: Icons.thermostat,
                  ),
                  SensorGauge(
                    label: 'Humidity',
                    value: state.currentHumidity ?? 45.0,
                    unit: '%',
                    minValue: 0,
                    maxValue: 100,
                    warningValue: SafetyThresholds.humidityWarningMax,
                    criticalValue: SafetyThresholds.humidityCriticalMax,
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
                  data: state.temperatureHistory.isNotEmpty
                      ? state.temperatureHistory
                      : List.generate(24, (i) => FlSpot(i.toDouble(), 23 + (i % 6) * 0.35)),
                  title: 'Temperature trend',
                  unit: 'C',
                  lineColor: AppColors.environment,
                  warningThreshold: SafetyThresholds.tempWarningMax,
                  criticalThreshold: SafetyThresholds.tempCriticalMax,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text('VOC ${state.currentVoc?.toStringAsFixed(0) ?? '120'} ppb'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.bottomSafeArea)),
          ],
        );
      },
    );
  }
}
