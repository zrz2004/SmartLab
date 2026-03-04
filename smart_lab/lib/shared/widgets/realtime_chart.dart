import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// 实时数据图表组件
/// 
/// 用于显示传感器数据的时序曲线
class RealtimeChart extends StatelessWidget {
  final List<FlSpot> data;
  final String title;
  final String unit;
  final double? minY;
  final double? maxY;
  final Color lineColor;
  final Color? gradientColor;
  final double? warningThreshold;
  final double? criticalThreshold;
  
  const RealtimeChart({
    super.key,
    required this.data,
    required this.title,
    required this.unit,
    this.minY,
    this.maxY,
    this.lineColor = AppColors.primary,
    this.gradientColor,
    this.warningThreshold,
    this.criticalThreshold,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.safeLight,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.safe,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '实时更新',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.safe,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // 当前数值
          if (data.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data.last.y.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: 'DINAlternate',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // 图表
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateInterval(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.divider,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _calculateInterval(),
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: data.isNotEmpty ? data.first.x : 0,
                maxX: data.isNotEmpty ? data.last.x : 10,
                minY: minY ?? (data.isNotEmpty ? _calculateMinY() : 0),
                maxY: maxY ?? (data.isNotEmpty ? _calculateMaxY() : 100),
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (gradientColor ?? lineColor).withOpacity(0.3),
                          (gradientColor ?? lineColor).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                // 阈值线
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (warningThreshold != null)
                      HorizontalLine(
                        y: warningThreshold!,
                        color: AppColors.warning.withOpacity(0.5),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    if (criticalThreshold != null)
                      HorizontalLine(
                        y: criticalThreshold!,
                        color: AppColors.critical.withOpacity(0.5),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                  ],
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppColors.textPrimary,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)} $unit',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 250),
            ),
          ),
          
          // 阈值图例
          if (warningThreshold != null || criticalThreshold != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (warningThreshold != null) ...[
                  Container(
                    width: 12,
                    height: 2,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '预警: $warningThreshold$unit',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                if (criticalThreshold != null) ...[
                  Container(
                    width: 12,
                    height: 2,
                    color: AppColors.critical,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '报警: $criticalThreshold$unit',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  double _calculateMinY() {
    if (data.isEmpty) return 0;
    final minValue = data.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    return (minValue - 5).clamp(0, double.infinity);
  }
  
  double _calculateMaxY() {
    if (data.isEmpty) return 100;
    final maxValue = data.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    return maxValue + 5;
  }
  
  double _calculateInterval() {
    final range = (_calculateMaxY() - _calculateMinY());
    if (range <= 10) return 2;
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    return 50;
  }
}
